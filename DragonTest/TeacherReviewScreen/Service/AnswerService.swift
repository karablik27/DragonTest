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

    // MARK: - Ученик начинает/возобновляет попытку
    func startAttempt(testId: String, studentId: String) async throws -> StudentAttempt {
        if let existing = try await fetchInProgressAttempt(testId: testId, studentId: studentId) {
            return existing
        }

        let ref = dataBase.collection("attempts").document()
        let payload: [String: Any] = [
            "id": ref.documentID,
            "testId": testId,
            "studentId": studentId,
            "answers": [],
            "submittedAt": FieldValue.serverTimestamp(),
            "reviewed": false,
            "status": AttemptStatus.inProgress.rawValue,
            "startedAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp(),
            "currentIndex": 0,
            "exitCount": 0,
            "suspicious": false
        ]

        try await ref.setData(payload)

        let snapshot = try await ref.getDocument()
        if let created = try? snapshot.data(as: StudentAttempt.self) {
            return created
        }

        let now = Date()
        return StudentAttempt(
            id: ref.documentID,
            testId: testId,
            studentId: studentId,
            answers: [],
            submittedAt: now,
            reviewed: false,
            status: .inProgress,
            startedAt: now,
            lastActiveAt: now,
            currentIndex: 0,
            exitCount: 0,
            suspicious: false,
            resultId: nil,
            result: nil
        )
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

    func saveAttemptProgress(_ attempt: StudentAttempt) async throws {
        var updated = attempt
        updated.status = .inProgress
        updated.reviewed = false
        updated.lastActiveAt = Date()

        try dataBase.collection("attempts")
            .document(updated.id)
            .setData(from: updated)
    }

    func claimAttemptForAIReview(_ attemptId: String) async throws -> Bool {
        let ref = dataBase.collection("attempts").document(attemptId)
        let staleLockThreshold: TimeInterval = 180

        let result = try await dataBase.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)
                guard snapshot.exists else { return false }

                let data = snapshot.data() ?? [:]
                let status = data["status"] as? String ?? AttemptStatus.submitted.rawValue
                let reviewed = data["reviewed"] as? Bool ?? false
                let resultId = data["resultId"] as? String
                let aiReviewingAt = data["aiReviewingAt"] as? Timestamp

                guard !reviewed, resultId == nil else { return false }

                if status == AttemptStatus.aiReviewing.rawValue,
                   let lockTime = aiReviewingAt?.dateValue(),
                   Date().timeIntervalSince(lockTime) < staleLockThreshold {
                    return false
                }

                guard status == AttemptStatus.submitted.rawValue ||
                        status == AttemptStatus.aiReviewing.rawValue else { return false }

                transaction.updateData([
                    "status": AttemptStatus.aiReviewing.rawValue,
                    "aiReviewingAt": FieldValue.serverTimestamp(),
                    "lastActiveAt": FieldValue.serverTimestamp()
                ], forDocument: ref)
                return true
            } catch let error as NSError {
                errorPointer?.pointee = error
                return false
            }
        }

        return result as? Bool ?? false
    }

    func markAttemptSubmittedForAIReviewRetry(_ attemptId: String) async throws {
        try await dataBase.collection("attempts")
            .document(attemptId)
            .updateData([
                "status": AttemptStatus.submitted.rawValue,
                "aiReviewingAt": FieldValue.delete(),
                "lastActiveAt": FieldValue.serverTimestamp()
            ])

        postAttemptReviewChanged(attemptId: attemptId, testId: nil, studentId: nil)
    }

    // MARK: - Ученик отправляет свои ответы
    func submitAttempt(_ attempt: StudentAttempt) async throws {
        var finalAttempt = attempt
        let now = Date()
        finalAttempt.submittedAt = now
        finalAttempt.lastActiveAt = now
        finalAttempt.status = .submitted
        finalAttempt.reviewed = false

        try dataBase.collection("attempts")
            .document(finalAttempt.id)
            .setData(from: finalAttempt)
    }

    // MARK: - Ученик получает результат (если есть)
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

    // MARK: - Учитель получает все попытки по тесту
    func fetchAttempts(for testId: String) async throws -> [StudentAttempt] {
        let snapshot = try await dataBase.collection("attempts")
            .whereField("testId", isEqualTo: testId)
            .getDocuments()

        var attempts = try snapshot.documents.compactMap { try $0.data(as: StudentAttempt.self) }
            .filter { $0.normalizedStatus != .inProgress }

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
                guard let attempt = try? document.data(as: StudentAttempt.self) else { continue }
                guard attempt.normalizedStatus != .inProgress else { continue }

                uniqueStudentsByTestId[attempt.testId, default: []].insert(attempt.studentId)

                if attempt.normalizedStatus != .reviewed {
                    let testId = attempt.testId
                    let studentId = attempt.studentId
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

        let reviewedByTeacher = result.teacherReviewedAt != nil
        try await dataBase.collection("attempts")
            .document(attemptId)
            .updateData([
                "reviewed": reviewedByTeacher,
                "resultId": result.id,
                "status": reviewedByTeacher ? AttemptStatus.reviewed.rawValue : AttemptStatus.submitted.rawValue,
                "aiReviewingAt": FieldValue.delete(),
                "lastActiveAt": FieldValue.serverTimestamp()
            ])

        postAttemptReviewChanged(
            attemptId: attemptId,
            testId: result.testId,
            studentId: result.studentId
        )
    }

    private func postAttemptReviewChanged(attemptId: String, testId: String?, studentId: String?) {
        var userInfo: [AnyHashable: Any] = [
            AttemptNotificationUserInfoKey.attemptId: attemptId
        ]
        if let testId {
            userInfo[AttemptNotificationUserInfoKey.testId] = testId
        }
        if let studentId {
            userInfo[AttemptNotificationUserInfoKey.studentId] = studentId
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .attemptReviewDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    private func reviewedTimestamp(for result: TestResult) -> Date {
        result.teacherReviewedAt ?? result.llmReviewedAt ?? Date.distantPast
    }
}
