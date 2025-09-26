//
//  TestResult.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation

struct TestResult: Codable, Identifiable {
    var id: String                // UUID результата
    var testId: String            // ссылка на тест
    var studentId: String         // ссылка на ученика
    
    // --- Итоги по тесту ---
    var answers: [StudentAnswer]  // все ответы с комментариями
    var totalScore: Int           // финальный балл по тесту
    var completed: Int            // количество вопросов с >=4 баллов
    var capturedDragon: Bool      // true если totalScore >= 8
    
    // --- Общие комментарии ---
    var teacherComment: String?   // общий комментарий от учителя
    var llmComment: String?       // общий комментарий от LLM
    
    // --- Время проверки ---
    var llmReviewedAt: Date?      // когда проверил ИИ
    var teacherReviewedAt: Date?  // когда проверил учитель
}

