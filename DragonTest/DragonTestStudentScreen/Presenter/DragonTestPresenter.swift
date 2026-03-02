//
//  DragonTestPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 26.09.2025.
//

import Foundation
import UIKit

final class DragonTestPresenter: DragonTestPresenterProtocol {
    private weak var view: DragonTestViewProtocol?
    private let test: Test
    private var attempt: StudentAttempt?
    private let resumeAttempt: StudentAttempt?
    private let testDuration: TimeInterval = 60 * 60
    private let maxAllowedExits = 3

    var currentIndex = 0
    private var timer: Timer?
    private var timeRemaining: TimeInterval = 0
    private var progressSaveTask: Task<Void, Never>?
    private var isSubmitting = false

    private(set) var answered: [Bool]

    // MARK: - Init
    init(view: DragonTestViewProtocol, test: Test, resumeAttempt: StudentAttempt? = nil) {
        self.view = view
        self.test = test
        self.resumeAttempt = resumeAttempt
        self.answered = Array(repeating: false, count: test.questions.count)
    }

    // MARK: - Protocol props
    var questionsCount: Int { test.questions.count }
    private var remainingExits: Int {
        let used = attempt?.safeExitCount ?? 0
        return max(0, maxAllowedExits - used)
    }

    // MARK: - Lifecycle
    func viewDidLoad() {
        Task { [weak self] in
            await self?.prepareAttemptAndStart()
        }
    }

    func appDidEnterBackground() {
        guard !isSubmitting else { return }

        Task { [weak self] in
            guard let self else { return }
            await self.persistProgressNow()
            guard var attempt = self.attempt else { return }
            guard attempt.normalizedStatus == .inProgress else { return }

            let newExitCount = attempt.safeExitCount + 1
            attempt.exitCount = newExitCount
            attempt.lastActiveAt = Date()
            self.attempt = attempt

            do {
                try await DependencyInjection.shared.answerService.saveAttemptProgress(attempt)
            } catch {
                print("Ошибка сохранения выхода: \(error)")
            }

            if newExitCount >= self.maxAllowedExits {
                self.submitCurrentAttempt(showAlert: false, markSuspicious: true, fillMissingAnswers: true)
            }
        }
    }

    // MARK: - Timer
    private func startTimer() {
        recalculateTimeRemaining()
        updateTimerLabel()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.recalculateTimeRemaining()
            self.updateTimerLabel()
            if self.timeRemaining <= 0 {
                t.invalidate()
                self.forceFinishTest()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func recalculateTimeRemaining() {
        guard let attempt else {
            timeRemaining = 0
            return
        }
        let endAt = attempt.safeStartedAt.addingTimeInterval(testDuration)
        timeRemaining = max(0, endAt.timeIntervalSinceNow)
    }

    private func updateTimerLabel() {
        let min = Int(timeRemaining) / 60
        let sec = Int(timeRemaining) % 60
        let text = String(format: "%02d:%02d", min, sec)
        view?.updateTimerLabel(text: text)
    }

    // MARK: - Show Question
    private func showCurrentQuestion() {
        guard let attempt else { return }
        guard currentIndex < test.questions.count else {
            submitCurrentAttempt(showAlert: true, markSuspicious: false, fillMissingAnswers: false)
            return
        }
        let q = test.questions[currentIndex]
        let savedAnswer = attempt.answers.first(where: { $0.questionId == q.id })
        view?.showQuestion(
            text: q.text,
            options: q.type == .select ? q.options : nil,
            answerText: savedAnswer?.textAnswer
        )
    }

    // MARK: - Answers
    func answerSelected(index: Int?) {
        guard !isSubmitting else { return }
        saveAnswer(selectedIndex: index, text: nil)
        answered[currentIndex] = true
        moveToNextOrFinish()
        scheduleProgressSave()
    }

    func textAnswerSubmitted(text: String?) {
        guard !isSubmitting else { return }
        let isValid = !(text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isValid {
            saveAnswer(selectedIndex: nil, text: text)
            answered[currentIndex] = true
        }
        moveToNextOrFinish()
        scheduleProgressSave()
    }

    func questionTapped(at index: Int) {
        guard !isSubmitting else { return }
        currentIndex = index
        showCurrentQuestion()
        scheduleProgressSave()
    }

    func helpTapped() {
        view?.showInfoAlert(remainingExits: remainingExits)
    }

    private func saveAnswer(selectedIndex: Int?, text: String?) {
        guard var attempt else { return }
        guard currentIndex >= 0, currentIndex < test.questions.count else { return }

        let q = test.questions[currentIndex]
        let studentId = attempt.studentId
        let id = "\(q.id)_\(studentId)"

        let answer = StudentAnswer(
            id: id,
            questionId: q.id,
            studentId: studentId,
            testId: test.id,
            textAnswer: text,
            selectedIndex: selectedIndex,
            teacherScore: nil,
            teacherComment: nil,
            llmScore: nil,
            llmComment: nil,
            finalScore: nil
        )

        if let idx = attempt.answers.firstIndex(where: { $0.id == id }) {
            attempt.answers[idx] = answer
        } else {
            attempt.answers.append(answer)
        }

        self.attempt = attempt
    }

    private func moveToNextOrFinish() {
        if currentIndex + 1 < questionsCount {
            currentIndex += 1
            showCurrentQuestion()
        } else {
            if answered.allSatisfy({ $0 }) {
                view?.showPreSubmitAlert { [weak self] in
                    self?.submitCurrentAttempt(showAlert: true, markSuspicious: false, fillMissingAnswers: false)
                }
            } else {
                view?.showError(message: "Ответьте на все вопросы, прежде чем завершить тест.")
            }
        }
    }

    private func appendMissingAnswers(to attempt: inout StudentAttempt) {
        let studentId = attempt.studentId

        for q in test.questions {
            let id = "\(q.id)_\(studentId)"
            if attempt.answers.first(where: { $0.id == id }) == nil {
                attempt.answers.append(
                    StudentAnswer(
                        id: id,
                        questionId: q.id,
                        studentId: studentId,
                        testId: test.id,
                        textAnswer: nil,
                        selectedIndex: nil,
                        teacherScore: nil,
                        teacherComment: nil,
                        llmScore: nil,
                        llmComment: nil,
                        finalScore: nil
                    )
                )
            }
        }
    }

    // MARK: - Finish
    private func submitCurrentAttempt(showAlert: Bool,
                                      markSuspicious: Bool,
                                      fillMissingAnswers: Bool) {
        guard !isSubmitting else { return }
        guard var attempt else { return }

        isSubmitting = true
        timer?.invalidate()
        timer = nil
        progressSaveTask?.cancel()
        progressSaveTask = nil

        if fillMissingAnswers {
            appendMissingAnswers(to: &attempt)
        }
        if markSuspicious {
            attempt.suspicious = true
        }

        attempt.currentIndex = currentIndex
        attempt.lastActiveAt = Date()
        self.attempt = attempt

        Task {
            do {
                try await DependencyInjection.shared.answerService.submitAttempt(attempt)
                self.attempt?.status = .submitted

                if showAlert {
                    await MainActor.run {
                        self.view?.showFinishAlert(answerCount: attempt.answers.count)
                    }
                }

                runAIReview(for: attempt)
            } catch {
                await MainActor.run {
                    self.view?.showError(message: "Не удалось отправить ответы")
                }
            }
            self.isSubmitting = false
        }
    }

    func forceFinishTest() {
        submitCurrentAttempt(showAlert: true, markSuspicious: false, fillMissingAnswers: true)
    }

    private func runAIReview(for attempt: StudentAttempt) {
        let questions = test.questions
        Task.detached {
            do {
                let claimed = try await DependencyInjection.shared.answerService.claimAttemptForAIReview(attempt.id)
                guard claimed else { return }

                let aiService = DependencyInjection.shared.aiReviewService
                let reviewedAnswers = try await aiService.reviewAnswers(
                    attempt.answers,
                    questions: questions
                )

                let totalScore = reviewedAnswers.compactMap { $0.llmScore }.reduce(0, +)
                let completed = reviewedAnswers.filter { ($0.llmScore ?? 0) >= 4 }.count

                let result = TestResult(
                    id: UUID().uuidString,
                    testId: attempt.testId,
                    studentId: attempt.studentId,
                    answers: reviewedAnswers,
                    totalScore: totalScore,
                    completed: completed,
                    capturedDragon: totalScore >= 320,
                    teacherComment: nil,
                    llmComment: "ИИ проверил автоматически",
                    llmReviewedAt: Date(),
                    teacherReviewedAt: nil
                )

                try await DependencyInjection.shared.answerService.reviewAttempt(attempt.id, result: result)
            } catch {
                try? await DependencyInjection.shared.answerService.markAttemptSubmittedForAIReviewRetry(attempt.id)
                print("Ошибка фоновой проверки ИИ: \(error)")
            }
        }
    }

    // MARK: - Progress
    private func scheduleProgressSave() {
        progressSaveTask?.cancel()
        progressSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await self?.persistProgressNow()
        }
    }

    private func persistProgressNow() async {
        guard !isSubmitting else { return }
        guard var attempt else { return }
        guard attempt.normalizedStatus == .inProgress else { return }

        attempt.currentIndex = currentIndex
        attempt.lastActiveAt = Date()
        attempt.status = .inProgress
        self.attempt = attempt

        do {
            try await DependencyInjection.shared.answerService.saveAttemptProgress(attempt)
        } catch {
            print("Ошибка сохранения прогресса: \(error)")
        }
    }

    private func prepareAttemptAndStart() async {
        let studentId = DependencyInjection.shared.currentUser.userId ?? "unknown"

        do {
            var preparedAttempt: StudentAttempt

            if let resumeAttempt, resumeAttempt.testId == test.id, resumeAttempt.studentId == studentId {
                preparedAttempt = resumeAttempt
            } else {
                if let completed = try await DependencyInjection.shared.resultService.fetchAttempt(
                    testId: test.id,
                    studentId: studentId
                ),
                   completed.normalizedStatus != .inProgress {
                    await MainActor.run {
                        self.view?.showError(message: "Тест уже отправлен на проверку. Повторное прохождение недоступно.")
                    }
                    return
                }

                if let existing = try await DependencyInjection.shared.answerService.fetchInProgressAttempt(
                    testId: test.id,
                    studentId: studentId
                ) {
                    preparedAttempt = existing
                } else {
                    preparedAttempt = try await DependencyInjection.shared.answerService.startAttempt(
                        testId: test.id,
                        studentId: studentId
                    )
                }
            }

            preparedAttempt.status = .inProgress
            preparedAttempt.startedAt = preparedAttempt.startedAt ?? preparedAttempt.submittedAt
            preparedAttempt.lastActiveAt = Date()
            preparedAttempt.currentIndex = preparedAttempt.currentIndex ?? 0
            preparedAttempt.exitCount = preparedAttempt.exitCount ?? 0
            preparedAttempt.suspicious = preparedAttempt.suspicious ?? false

            let restoredIndex = max(0, min(preparedAttempt.safeCurrentIndex, max(questionsCount - 1, 0)))
            attempt = preparedAttempt
            currentIndex = restoredIndex
            answered = buildAnsweredFlags(from: preparedAttempt.answers)

            if preparedAttempt.safeExitCount >= maxAllowedExits {
                submitCurrentAttempt(showAlert: true, markSuspicious: true, fillMissingAnswers: true)
                return
            }

            await MainActor.run {
                self.startTimer()
                self.showCurrentQuestion()
            }

            Task { [weak self] in
                await self?.persistProgressNow()
            }
        } catch {
            await MainActor.run {
                self.view?.showError(message: "Не удалось восстановить попытку")
            }
        }
    }

    private func buildAnsweredFlags(from answers: [StudentAnswer]) -> [Bool] {
        test.questions.map { question in
            guard let answer = answers.first(where: { $0.questionId == question.id }) else { return false }
            if answer.selectedIndex != nil { return true }
            let text = (answer.textAnswer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty
        }
    }
}
