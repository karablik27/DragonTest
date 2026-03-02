//
//  StudentAttempt.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//

import Foundation

enum AttemptStatus: String, Codable {
    case inProgress = "in_progress"
    case submitted = "submitted"
    case aiReviewing = "ai_reviewing"
    case reviewed = "reviewed"
}

struct StudentAttempt: Codable, Identifiable {
    var id: String            // UUID попытки
    var testId: String        // к какому тесту
    var studentId: String     // кто проходит

    var answers: [StudentAnswer] // все ответы
    var submittedAt: Date        // когда отправил
    var reviewed: Bool           // проверено ли учителем

    var status: AttemptStatus?
    var startedAt: Date?
    var lastActiveAt: Date?
    var currentIndex: Int?
    var exitCount: Int?
    var suspicious: Bool?

    var resultId: String?     // ссылка на документ в results
    var result: TestResult?   // подгружается отдельно при fetch

    var normalizedStatus: AttemptStatus {
        if let status { return status }
        return reviewed ? .reviewed : .submitted
    }

    var safeStartedAt: Date {
        startedAt ?? submittedAt
    }

    var safeLastActiveAt: Date {
        lastActiveAt ?? submittedAt
    }

    var safeCurrentIndex: Int {
        max(0, currentIndex ?? 0)
    }

    var safeExitCount: Int {
        max(0, exitCount ?? 0)
    }

    var isSuspicious: Bool {
        suspicious ?? false
    }

    init(
        id: String,
        testId: String,
        studentId: String,
        answers: [StudentAnswer],
        submittedAt: Date,
        reviewed: Bool,
        status: AttemptStatus? = nil,
        startedAt: Date? = nil,
        lastActiveAt: Date? = nil,
        currentIndex: Int? = nil,
        exitCount: Int? = nil,
        suspicious: Bool? = nil,
        resultId: String? = nil,
        result: TestResult? = nil
    ) {
        self.id = id
        self.testId = testId
        self.studentId = studentId
        self.answers = answers
        self.submittedAt = submittedAt
        self.reviewed = reviewed
        self.status = status
        self.startedAt = startedAt
        self.lastActiveAt = lastActiveAt
        self.currentIndex = currentIndex
        self.exitCount = exitCount
        self.suspicious = suspicious
        self.resultId = resultId
        self.result = result
    }

    enum CodingKeys: String, CodingKey {
        case id
        case testId
        case studentId
        case answers
        case submittedAt
        case reviewed
        case status
        case startedAt
        case lastActiveAt
        case currentIndex
        case exitCount
        case suspicious
        case resultId
        case result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        testId = try container.decode(String.self, forKey: .testId)
        studentId = try container.decode(String.self, forKey: .studentId)
        answers = try container.decodeIfPresent([StudentAnswer].self, forKey: .answers) ?? []
        submittedAt = try container.decodeIfPresent(Date.self, forKey: .submittedAt) ?? Date()
        reviewed = try container.decodeIfPresent(Bool.self, forKey: .reviewed) ?? false

        status = try container.decodeIfPresent(AttemptStatus.self, forKey: .status)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        lastActiveAt = try container.decodeIfPresent(Date.self, forKey: .lastActiveAt)
        currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex)
        exitCount = try container.decodeIfPresent(Int.self, forKey: .exitCount)
        suspicious = try container.decodeIfPresent(Bool.self, forKey: .suspicious)

        resultId = try container.decodeIfPresent(String.self, forKey: .resultId)
        result = try container.decodeIfPresent(TestResult.self, forKey: .result)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(testId, forKey: .testId)
        try container.encode(studentId, forKey: .studentId)
        try container.encode(answers, forKey: .answers)
        try container.encode(submittedAt, forKey: .submittedAt)
        try container.encode(reviewed, forKey: .reviewed)

        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(lastActiveAt, forKey: .lastActiveAt)
        try container.encodeIfPresent(currentIndex, forKey: .currentIndex)
        try container.encodeIfPresent(exitCount, forKey: .exitCount)
        try container.encodeIfPresent(suspicious, forKey: .suspicious)

        try container.encodeIfPresent(resultId, forKey: .resultId)
        try container.encodeIfPresent(result, forKey: .result)
    }
}
