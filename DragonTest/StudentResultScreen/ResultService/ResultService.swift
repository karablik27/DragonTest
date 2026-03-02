//
//  ResultService.swift
//  DragonTest
//
//  Created by Карабельников Степан on 25.09.2025.
//

import Foundation
import FirebaseFirestore

final class ResultService: ResultServiceProtocol {
    private let dataBase: Firestore

    init(dataBase: Firestore) {
        self.dataBase = dataBase
    }

    func fetchInProgressAttempt(testId: String, studentId: String) async throws -> StudentAttempt? {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        let attempts = try snapshot.documents.compactMap { try $0.data(as: StudentAttempt.self) }
        let inProgress = attempts.filter { $0.normalizedStatus == .inProgress }
        return inProgress.max(by: { $0.safeStartedAt < $1.safeStartedAt })
    }

    func fetchAttempt(testId: String, studentId: String) async throws -> StudentAttempt? {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        let attempts = try snapshot.documents.compactMap { try $0.data(as: StudentAttempt.self) }
        let completed = attempts.filter { $0.normalizedStatus != .inProgress }
        let hydrated = try await attachResults(to: completed)
        return hydrated.max(by: { $0.submittedAt < $1.submittedAt })
    }

    func fetchResult(testId: String, studentId: String) async throws -> TestResult? {
        let snapshot = try await dataBase.collection("results")
            .whereField("testId", isEqualTo: testId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        let results = try snapshot.documents.compactMap { try $0.data(as: TestResult.self) }
        return results.max { lhs, rhs in
            reviewedTimestamp(for: lhs) < reviewedTimestamp(for: rhs)
        }
    }

    func fetchAttempts(studentId: String) async throws -> [StudentAttempt] {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        let attempts = try snapshot.documents
            .compactMap { try $0.data(as: StudentAttempt.self) }
            .filter { $0.normalizedStatus != .inProgress }

        return try await attachResults(to: attempts)
    }

    private func attachResults(to attempts: [StudentAttempt]) async throws -> [StudentAttempt] {
        guard !attempts.isEmpty else { return attempts }

        var hydrated = attempts
        for index in hydrated.indices {
            guard let resultId = hydrated[index].resultId else { continue }
            let snap = try await dataBase.collection("results").document(resultId).getDocument()
            guard snap.exists else { continue }
            hydrated[index].result = try snap.data(as: TestResult.self)
        }

        return hydrated
    }

    private func reviewedTimestamp(for result: TestResult) -> Date {
        result.teacherReviewedAt ?? result.llmReviewedAt ?? Date.distantPast
    }
}
