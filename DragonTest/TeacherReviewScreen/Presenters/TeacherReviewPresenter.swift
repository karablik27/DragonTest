//
//  TeacherReviewPresenter.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//


import Foundation

protocol TeacherReviewPresenterProtocol {
    func viewDidLoad()
}

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
                // 1. Загружаем студентов, у которых есть доступ
                let users = try await di.userService.fetchStudentsForTests(for: test)
                // 2. Загружаем все попытки для этого теста
                let attempts = try await di.answerService.fetchAttempts(for: test.id)
                
                // 3. Собираем StudentRowModel
                let rows = users.map { user in
                    let attempt = attempts.first { $0.studentId == user.id }
                    return StudentRowModel(user: user, attempt: attempt)
                }
                
                await MainActor.run {
                    self.view?.showStudents(rows)
                }
            } catch {
                await MainActor.run {
                    self.view?.showError("teacher.error.load_failed".localized)
                }
            }
        }
    }
}

