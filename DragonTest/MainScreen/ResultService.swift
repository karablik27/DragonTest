//
//  ResultService.swift
//  DragonTest
//
//  Created by Верховный Маг on 25.09.2025.
//

// ResultService.swift
// DragonTest

import Foundation
import FirebaseFirestore

final class ResultService: ResultServiceProtocol {
    private let dataBase: Firestore

    init(dataBase: Firestore) {
        self.dataBase = dataBase
    }

    func fetchAttempt(testId: String, studentId: String) async throws -> StudentAttempt? {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: StudentAttempt.self)
    }

    func fetchResult(testId: String, studentId: String) async throws -> TestResult? {
        let snapshot = try await dataBase.collection("results")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return try doc.data(as: TestResult.self)
    }
}
