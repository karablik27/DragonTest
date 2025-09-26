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
    private var attempt: StudentAttempt
    var currentIndex = 0
    private var timer: Timer?
    private var timeRemaining: TimeInterval = 3604
    
    private(set) var answered: [Bool]

    // MARK: - Init
    init(view: DragonTestViewProtocol, test: Test) {
        self.view = view
        self.test = test
        self.answered = Array(repeating: false, count: test.questions.count)

        let studentId = DependencyInjection.shared.currentUser.userId ?? "unknown"
        self.attempt = StudentAttempt(
            id: UUID().uuidString,
            testId: test.id,
            studentId: studentId,
            answers: [],
            submittedAt: Date(),
            reviewed: false,
            result: nil
        )
    }

    // MARK: - Protocol props
    var questionsCount: Int { test.questions.count }

    // MARK: - Lifecycle
    func viewDidLoad() {
        startTimer()
        showCurrentQuestion()
    }

    // MARK: - Timer
    private func startTimer() {
        updateTimerLabel()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.timeRemaining -= 1
            self.updateTimerLabel()
            if self.timeRemaining <= 0 {
                t.invalidate()
                self.forceFinishTest()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func updateTimerLabel() {
        let min = Int(timeRemaining) / 60
        let sec = Int(timeRemaining) % 60
        let text = String(format: "%02d:%02d", min, sec)
        view?.updateTimerLabel(text: text)
    }

    // MARK: - Show Question
    private func showCurrentQuestion() {
        guard currentIndex < test.questions.count else {
            finishTest()
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
        saveAnswer(selectedIndex: index, text: nil)
        answered[currentIndex] = true
        moveToNextOrFinish()
    }

    func textAnswerSubmitted(text: String?) {
        let isValid = !(text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isValid {
            saveAnswer(selectedIndex: nil, text: text)
            answered[currentIndex] = true
        }
        moveToNextOrFinish()
    }

    func questionTapped(at index: Int) {
        currentIndex = index
        showCurrentQuestion()
    }

    private func saveAnswer(selectedIndex: Int?, text: String?) {
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
    }

    private func moveToNextOrFinish() {
        if currentIndex + 1 < questionsCount {
            currentIndex += 1
            showCurrentQuestion()
        } else {
            if answered.allSatisfy({ $0 }) {
                finishTest()
            } else {
                view?.showError(message: "Ответьте на все вопросы, прежде чем завершить тест.")
            }
        }
    }

    // MARK: - Finish
    private func finishTest() {
        timer?.invalidate()
        timer = nil

        Task {
            do {
                try await DependencyInjection.shared.answerService.submitAttempt(attempt)
                await MainActor.run {
                    self.view?.showFinishAlert(answerCount: attempt.answers.count)
                }
                runAIReview()
            } catch {
                await MainActor.run {
                    self.view?.showError(message: "Не удалось отправить ответы")
                }
            }
        }
    }

    func forceFinishTest() {
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
        finishTest()
    }

    private func runAIReview() {
        Task.detached {
            do {
                let aiService = DependencyInjection.shared.aiReviewService
                let reviewedAnswers = try await aiService.reviewAnswers(
                    self.attempt.answers,
                    questions: self.test.questions
                )

                let totalScore = reviewedAnswers.compactMap { $0.llmScore }.reduce(0, +)
                let completed = reviewedAnswers.filter { ($0.llmScore ?? 0) >= 4 }.count

                let result = TestResult(
                    id: UUID().uuidString,
                    testId: self.attempt.testId,
                    studentId: self.attempt.studentId,
                    answers: reviewedAnswers,
                    totalScore: totalScore,
                    completed: completed,
                    capturedDragon: totalScore >= 320,
                    teacherComment: nil,
                    llmComment: "ИИ проверил автоматически",
                    llmReviewedAt: Date(),
                    teacherReviewedAt: nil
                )

                try await DependencyInjection.shared.answerService.reviewAttempt(self.attempt.id, result: result)
            } catch {
                print("Ошибка фоновой проверки ИИ: \(error)")
            }
        }
    }
}
