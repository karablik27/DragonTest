//
//  AnswerService.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

import Foundation
import FirebaseFirestore

final class AnswerService: AnswerServiceProtocol {
    private let dataBase: Firestore

    init(dataBase: Firestore) {
        self.dataBase = dataBase
    }

    // MARK: - Ученик отправляет свои ответы
    func submitAttempt(_ attempt: StudentAttempt) async throws {
        try dataBase.collection("attempts")
            .document(attempt.id)
            .setData(from: attempt)
    }

    // MARK: - Ученик получает результат (если есть)
    func fetchResult(testId: String, studentId: String) async throws -> TestResult? {
        let snapshot = try await dataBase.collection("results")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: TestResult.self)
    }

    // MARK: - Учитель получает все попытки по тесту
    func fetchAttempts(for testId: String) async throws -> [StudentAttempt] {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .getDocuments()

        var attempts = try snapshot.documents.compactMap { try $0.data(as: StudentAttempt.self) }

        // Подгружаем result, если есть resultId
        for i in attempts.indices {
            if let resultId = attempts[i].resultId {
                let resultSnap = try await dataBase.collection("results").document(resultId).getDocument()
                if resultSnap.exists {
                    attempts[i].result = try resultSnap.data(as: TestResult.self)
                }
            }
        }
        return attempts
    }

    // MARK: - Учитель/ИИ сохраняет проверку
    func reviewAttempt(_ attemptId: String, result: TestResult) async throws {
        // 1. Сохраняем результат в results
        try dataBase.collection("results")
            .document(result.id)
            .setData(from: result)

        // 2. Привязываем result к attempt
        try await dataBase.collection("attempts")
            .document(attemptId)
            .updateData([
                "reviewed": true,
                "resultId": result.id
            ])
    }
}
