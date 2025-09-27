//
//  TeacherReviewPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//


import Foundation

final class TeacherReviewPresenter: TeacherReviewPresenterProtocol {
    
    private weak var view: TeacherReviewViewProtocol?
    private let test: Test
    private let di = DependencyInjection.shared
    
    init(view: TeacherReviewViewProtocol, test: Test) {
        self.view = view
        self.test = test
    }
    
    func viewDidLoad() {
        Task {
            do {
                let users = try await di.userService.fetchStudentsForTests(for: test)
                let attempts = try await di.answerService.fetchAttempts(for: test.id)
                let rows = users.map { user in
                    let attempt = attempts.first { $0.studentId == user.id }
                    return StudentRowModel(user: user, attempt: attempt)
                }
                await MainActor.run {
                    self.view?.showStudents(rows)
                }
            } catch {
                await MainActor.run {
                    self.view?.showError("Не удалось загрузить данные")
                }
            }
        }
    }
}

