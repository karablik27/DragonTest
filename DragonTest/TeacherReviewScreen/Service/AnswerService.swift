//
//  AnswerService.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
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

    // MARK: - Лёгкая агрегация статусов учителя (без догрузки results)
    func fetchTeacherStatusSummary(for testIds: [String]) async throws -> [String: TeacherTestStatusSummary] {
        guard !testIds.isEmpty else { return [:] }

        let uniqueTestIds = Array(Set(testIds))
        var uniqueStudentsByTestId: [String: Set<String>] = [:]
        var pendingStudentsByTestId: [String: Set<String>] = [:]

        for chunk in uniqueTestIds.chunked(into: 10) {
            let snapshot = try await dataBase.collection("attempts")
                .whereField("testId", in: chunk)
                .getDocuments()

            for document in snapshot.documents {
                let data = document.data()
                guard let testId = data["testId"] as? String,
                      let studentId = data["studentId"] as? String else { continue }

                let reviewed = data["reviewed"] as? Bool ?? false
                uniqueStudentsByTestId[testId, default: []].insert(studentId)

                if !reviewed {
                    pendingStudentsByTestId[testId, default: []].insert(studentId)
                }
            }
        }

        var summaryByTestId: [String: TeacherTestStatusSummary] = [:]
        for testId in uniqueTestIds {
            let uniqueCount = uniqueStudentsByTestId[testId]?.count ?? 0
            let pendingCount = pendingStudentsByTestId[testId]?.count ?? 0
            summaryByTestId[testId] = TeacherTestStatusSummary(
                uniqueStudentsCount: uniqueCount,
                pendingStudentsCount: pendingCount
            )
        }

        return summaryByTestId
    }

    // MARK: - Учитель/ИИ сохраняет проверку
    func reviewAttempt(_ attemptId: String, result: TestResult) async throws {
        try dataBase.collection("results")
            .document(result.id)
            .setData(from: result)

        try await dataBase.collection("attempts")
            .document(attemptId)
            .updateData([
                "reviewed": true,
                "resultId": result.id
            ])
    }
}
