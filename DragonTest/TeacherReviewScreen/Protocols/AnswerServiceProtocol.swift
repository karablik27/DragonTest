//
//  AnswerServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

//  AnswerServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

import Foundation

protocol AnswerServiceProtocol {
    /// Ученик отправляет свои ответы
    func submitAttempt(_ attempt: StudentAttempt) async throws
    
    /// Ученик получает результат (если проверен)
    func fetchResult(testId: String, studentId: String) async throws -> TestResult?
    
    /// Учитель получает все попытки по тесту
    func fetchAttempts(for testId: String) async throws -> [StudentAttempt]
    
    /// Учитель сохраняет проверку (результат)
    func reviewAttempt(_ attemptId: String, result: TestResult) async throws
}
