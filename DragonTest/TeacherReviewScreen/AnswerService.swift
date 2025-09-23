//
//  AnswerService.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

//  AnswerService.swift
import Foundation
import FirebaseFirestore

final class AnswerService: AnswerServiceProtocol {
    private let dataBase: Firestore

    init(dataBase: Firestore) {
        self.dataBase = dataBase
    }

    func submitAttempt(_ attempt: StudentAttempt) async throws {
        try dataBase.collection("attempts")
            .document(attempt.id)
            .setData(from: attempt)
    }

    func fetchResult(testId: String, studentId: String) async throws -> TestResult? {
        let snapshot = try await dataBase.collection("results")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: TestResult.self)
    }

    func fetchAttempts(for testId: String) async throws -> [StudentAttempt] {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: StudentAttempt.self) }
    }

    func reviewAttempt(_ attemptId: String, result: TestResult) async throws {
        try dataBase.collection("results")
            .document(result.id)
            .setData(from: result)

        try await dataBase.collection("attempts")
            .document(attemptId)
            .updateData(["reviewed": true])
    }
}
