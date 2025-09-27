//
//  AnswerServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//

import Foundation

protocol AnswerServiceProtocol {
    func submitAttempt(_ attempt: StudentAttempt) async throws
    func fetchResult(testId: String, studentId: String) async throws -> TestResult?
    func fetchAttempts(for testId: String) async throws -> [StudentAttempt]
    func reviewAttempt(_ attemptId: String, result: TestResult) async throws
}
