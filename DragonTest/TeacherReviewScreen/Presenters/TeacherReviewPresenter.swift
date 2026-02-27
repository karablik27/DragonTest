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

                var latestAttemptByStudentId: [String: StudentAttempt] = [:]
                for attempt in attempts {
                    if let existing = latestAttemptByStudentId[attempt.studentId] {
                        if attempt.submittedAt > existing.submittedAt {
                            latestAttemptByStudentId[attempt.studentId] = attempt
                        }
                    } else {
                        latestAttemptByStudentId[attempt.studentId] = attempt
                    }
                }

                let rows = users.map { user in
                    StudentRowModel(user: user, attempt: latestAttemptByStudentId[user.id])
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
