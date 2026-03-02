//
//  AIReviewRecoveryCoordinator.swift
//  DragonTest
//

import Foundation

actor AIReviewRecoveryCoordinator {
    static let shared = AIReviewRecoveryCoordinator()

    private var isRunning = false

    func recoverPendingAIReviews() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        let di = DependencyInjection.shared
        guard di.currentUser.role == .student,
              let studentId = di.currentUser.userId,
              !studentId.isEmpty else { return }

        do {
            let attempts = try await di.resultService.fetchAttempts(studentId: studentId)
            let pending = attempts.filter { attempt in
                let status = attempt.normalizedStatus
                return (status == .submitted || status == .aiReviewing) && attempt.resultId == nil
            }

            guard !pending.isEmpty else { return }

            let tests = try await di.testService.fetchTests()
            var testsById: [String: Test] = [:]
            for test in tests {
                testsById[test.id] = test
            }

            for attempt in pending.sorted(by: { $0.submittedAt < $1.submittedAt }) {
                guard let test = testsById[attempt.testId] else { continue }

                let claimed = try await di.answerService.claimAttemptForAIReview(attempt.id)
                guard claimed else { continue }

                do {
                    let reviewedAnswers = try await di.aiReviewService.reviewAnswers(
                        attempt.answers,
                        questions: test.questions
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

                    try await di.answerService.reviewAttempt(attempt.id, result: result)
                } catch {
                    try? await di.answerService.markAttemptSubmittedForAIReviewRetry(attempt.id)
                    print("Ошибка восстановления ИИ-проверки: \(error)")
                }
            }
        } catch {
            print("Ошибка запуска восстановления ИИ-проверки: \(error)")
        }
    }
}
