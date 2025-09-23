//
//  StudentAnswer.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation

struct StudentAnswer: Codable, Identifiable {
    var id: String               // уникальный id (например, questionId+studentId)
    var questionId: String       // id вопроса
    var studentId: String        // id студента
    var testId: String           // id теста
    
    // --- Ответ ученика ---
    var textAnswer: String?      // ответ для open-вопросов
    var selectedIndex: Int?      // индекс выбранного варианта для select
    
    // --- Проверка учителем ---
    var teacherScore: Int?       // балл (0–10)
    var teacherComment: String?  // комментарий учителя
    
    // --- Проверка LLM ---
    var llmScore: Int?           // балл от модели (0–10)
    var llmComment: String?      // комментарий модели
    
    // --- Итог по этому вопросу ---
    var finalScore: Int?         // итоговый балл за вопрос
}


