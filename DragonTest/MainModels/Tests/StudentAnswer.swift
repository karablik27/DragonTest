//
//  StudentAnswer.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation

struct StudentAnswer: Codable, Identifiable {
    var id: String             // id документа ответа (или совпадает с questionId+studentId)
    var questionId: String     // к какому вопросу относится
    var studentId: String      // id студента из Firestore
    var testId: String         // к какому тесту относится
    
    // ответы
    var textAnswer: String?    // для open
    var selectedIndex: Int?    // индекс варианта для select
    
    // проверки
    var isCorrectByLLM: Bool?   // проверка ИИ
    var isCorrectByTeacher: Bool? // проверка учителем
    
    // очки
    var score: Int?             // начисленные баллы
}

