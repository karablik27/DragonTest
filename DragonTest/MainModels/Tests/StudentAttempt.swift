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

    // --- Результаты ---
    var result: TestResult?      // ссылка на итоговую оценку (если проверено)
}
