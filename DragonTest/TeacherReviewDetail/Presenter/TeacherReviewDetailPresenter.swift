//
//  TeacherReviewDetailPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import Foundation
import UIKit

final class TeacherReviewDetailPresenter: TeacherReviewDetailPresenterProtocol {

    // MARK: - Weak view
    private weak var view: TeacherReviewDetailViewProtocol?

    // MARK: - DI / Model
    private let attempt: StudentAttempt
    private let answerService: AnswerServiceProtocol
    private let questions: [Questions]
    private let colors: [CGColor]
    private let testTitle: String

    private var answers: [StudentAnswer]
    private var isEditable: Bool {
        attempt.result?.teacherReviewedAt == nil
    }


    // MARK: - Init
    init(attempt: StudentAttempt,
         questions: [Questions],
         answerService: AnswerServiceProtocol,
         colors: [CGColor],
         testTitle: String)
    {
        self.attempt = attempt
        self.questions = questions
        self.answerService = answerService
        self.colors = colors
        self.testTitle = testTitle
        self.answers = attempt.result?.answers ?? attempt.answers
    }

    // MARK: - Attach
    func attach(view: TeacherReviewDetailViewProtocol) {
        self.view = view
    }

    // MARK: - Lifecycle
    func viewDidLoad() {
        view?.applyBackground(colors: colors)
        view?.setHeader(testTitle: testTitle)
        view?.showFooter(isEditable)
        view?.setSaveEnabled(allScored())
        view?.reloadAll()
    }

    // MARK: - Table API
    func numberOfRows() -> Int { answers.count }

    func item(at index: Int) -> (answer: StudentAnswer, questionText: String, isEditable: Bool) {
        let answer = answers[index]
        let qText = questions.first(where: { $0.id == answer.questionId })?.text ?? "Вопрос не найден"
        return (answer, qText, isEditable)
    }

    // MARK: - Events
    func didUpdateAnswer(at index: Int, to answer: StudentAnswer) {
        answers[index] = answer
        view?.setSaveEnabled(allScored())
    }

    func saveTapped() {
        guard allScored() else {
            view?.showMessage(
                title: "Не все вопросы оценены",
                message: "Поставьте баллы за каждый ответ перед сохранением.",
                onOK: nil
            )
            return
        }

        let totalScore = answers.compactMap { $0.teacherScore }.reduce(0, +)
        let completed = answers.filter { ($0.teacherScore ?? 0) >= 4 }.count

        let result = TestResult(
            id: attempt.result?.id ?? UUID().uuidString,
            testId: attempt.testId,
            studentId: attempt.studentId,
            answers: answers,
            totalScore: totalScore,
            completed: completed,
            capturedDragon: totalScore >= 320,
            teacherComment: "Оценка учителя сохранена",
            llmComment: attempt.result?.llmComment,
            llmReviewedAt: attempt.result?.llmReviewedAt,
            teacherReviewedAt: Date()
        )

        Task {
            do {
                try await answerService.reviewAttempt(attempt.id, result: result)
                await MainActor.run { [weak self] in
                    self?.view?.showMessage(
                        title: "Сохранено",
                        message: "Результат проверки отправлен",
                        onOK: { [weak self] in self?.view?.pop() }
                    )
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.view?.showMessage(
                        title: "Ошибка",
                        message: "Не удалось сохранить результат",
                        onOK: nil
                    )
                }
            }
        }
    }

    // MARK: - Helpers
    private func allScored() -> Bool {
        answers.allSatisfy { $0.teacherScore != nil }
    }
}
