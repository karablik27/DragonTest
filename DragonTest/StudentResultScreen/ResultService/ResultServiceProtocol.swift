//
//  ResultServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 25.09.2025.
//

import Foundation

protocol ResultServiceProtocol {
    func fetchInProgressAttempt(testId: String, studentId: String) async throws -> StudentAttempt?
    func fetchAttempt(testId: String, studentId: String) async throws -> StudentAttempt?
    func fetchResult(testId: String, studentId: String) async throws -> TestResult?
    func fetchAttempts(studentId: String) async throws -> [StudentAttempt]
}
