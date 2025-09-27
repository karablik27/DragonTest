//
//  StudentAttempt.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//

import Foundation

struct StudentAttempt: Codable, Identifiable {
    var id: String            // UUID попытки
    var testId: String        // к какому тесту
    var studentId: String     // кто проходит

    var answers: [StudentAnswer] // все ответы
    var submittedAt: Date        // когда отправил
    var reviewed: Bool           // проверено ли учителем

    var resultId: String?     // ссылка на документ в results
    var result: TestResult?   // подгружается отдельно при fetch
}
