//
//  AnswerServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//

import Foundation

struct TeacherTestStatusSummary {
    let uniqueStudentsCount: Int
    let pendingStudentsCount: Int
}

protocol AnswerServiceProtocol {
    func startAttempt(testId: String, studentId: String) async throws -> StudentAttempt
    func fetchInProgressAttempt(testId: String, studentId: String) async throws -> StudentAttempt?
    func saveAttemptProgress(_ attempt: StudentAttempt) async throws
    func claimAttemptForAIReview(_ attemptId: String) async throws -> Bool
    func markAttemptSubmittedForAIReviewRetry(_ attemptId: String) async throws
    func submitAttempt(_ attempt: StudentAttempt) async throws
    func fetchResult(testId: String, studentId: String) async throws -> TestResult?
    func fetchAttempts(for testId: String) async throws -> [StudentAttempt]
    func fetchTeacherStatusSummary(for testIds: [String]) async throws -> [String: TeacherTestStatusSummary]
    func reviewAttempt(_ attemptId: String, result: TestResult) async throws
}
