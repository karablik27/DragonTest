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
    }

    func viewDidLoad() {
        view?.setTitle("Результат: \(test.title)")
        view?.showStatus("Загрузка результата…")
        view?.showTeacherComment(nil, hidden: true)
        view?.showLLMSummary(nil, hidden: true)
        loadResult()
    }

    func numberOfRows() -> Int {
        result?.answers.count ?? 0
    }

    func answer(at index: Int) -> (answer: StudentAnswer, questionText: String)? {
        guard let answers = result?.answers, index >= 0, index < answers.count else { return nil }
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
                        self.view?.showStatus("✅ Проверено. Балл: \(res.totalScore)")

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
                        self?.view?.showStatus("⏳ Работа на проверке…")
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.view?.showStatus("❌ Ошибка загрузки результата")
                }
            }
        }
    }
}
