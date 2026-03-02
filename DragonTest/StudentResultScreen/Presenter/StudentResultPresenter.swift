//
//  StudentResultPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class StudentResultPresenter: StudentResultPresenterProtocol {
    private weak var view: StudentResultViewProtocol?
    private let test: Test
    private let attempt: StudentAttempt
    private let resultService: ResultServiceProtocol
    private var result: TestResult?

    // Внешний коллбэк на закрытие (прокидывается из VC)
    private let onClose: (() -> Void)?
    private var attemptReviewObserver: NSObjectProtocol?

    init(test: Test,
         attempt: StudentAttempt,
         resultService: ResultServiceProtocol,
         onClose: (() -> Void)? = nil) {
        self.test = test
        self.attempt = attempt
        self.resultService = resultService
        self.onClose = onClose
    }

    func attach(view: StudentResultViewProtocol) {
        self.view = view
        subscribeToAttemptUpdatesIfNeeded()
    }

    func viewDidLoad() {
        view?.setTitle("Результат: \(test.title)")
        view?.showStatus("Загрузка результата…")
        view?.showTeacherComment(nil, hidden: true)
        view?.showLLMSummary(nil, hidden: true)
        view?.reloadAnswers()
        loadResult()
    }

    func numberOfRows() -> Int {
        result?.answers.count ?? attempt.answers.count
    }

    func answer(at index: Int) -> (answer: StudentAnswer, questionText: String)? {
        let answers = result?.answers ?? attempt.answers
        guard index >= 0, index < answers.count else { return nil }
        let ans = answers[index]
        let qText = test.questions.first(where: { $0.id == ans.questionId })?.text ?? "Неизвестный вопрос"
        return (ans, qText)
    }

    func closeTapped() {
        onClose?()
    }

    // MARK: - Private

    private func loadResult() {
        Task {
            do {
                if let res = try await resultService.fetchResult(testId: test.id, studentId: attempt.studentId) {
                    self.result = res
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if res.teacherReviewedAt != nil {
                            self.view?.showStatus("✅ Проверено учителем. Балл: \(res.totalScore)")
                        } else {
                            self.view?.showStatus("🤖 Проверено ИИ, ждём проверки учителя")
                        }

                        if let teacherComment = res.teacherComment, !teacherComment.isEmpty {
                            self.view?.showTeacherComment("Комментарий учителя: \(teacherComment)", hidden: false)
                        } else {
                            self.view?.showTeacherComment(nil, hidden: true)
                        }

                        if let llmComment = res.llmComment, !llmComment.isEmpty {
                            self.view?.showLLMSummary("ИИ: \(llmComment)", hidden: false)
                        } else {
                            self.view?.showLLMSummary(nil, hidden: true)
                        }
                        self.view?.reloadAnswers()
                    }
                } else {
                    await MainActor.run { [weak self] in
                        self?.view?.showStatus("⏳ ИИ проверяет работу…")
                        self?.view?.reloadAnswers()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.view?.showStatus("❌ Ошибка загрузки результата")
                }
            }
        }
    }

    deinit {
        if let attemptReviewObserver {
            NotificationCenter.default.removeObserver(attemptReviewObserver)
        }
    }

    private func subscribeToAttemptUpdatesIfNeeded() {
        guard attemptReviewObserver == nil else { return }
        attemptReviewObserver = NotificationCenter.default.addObserver(
            forName: .attemptReviewDidChange,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }

            if let testId = note.userInfo?[AttemptNotificationUserInfoKey.testId] as? String,
               !testId.isEmpty,
               testId != self.test.id {
                return
            }

            if let studentId = note.userInfo?[AttemptNotificationUserInfoKey.studentId] as? String,
               !studentId.isEmpty,
               studentId != self.attempt.studentId {
                return
            }

            self.loadResult()
        }
    }
}
