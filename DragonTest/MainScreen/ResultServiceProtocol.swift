//
//  ResultServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 25.09.2025.
//

import Foundation

protocol ResultServiceProtocol {
    /// Получить попытку ученика (если она есть)
    func fetchAttempt(testId: String, studentId: String) async throws -> StudentAttempt?

    /// Получить результат проверки
    func fetchResult(testId: String, studentId: String) async throws -> TestResult?
}
