//
//  Question.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

enum QuestionType: String, Codable {
    case open      // открытый вопрос с текстовым вводом
    case select    // выбор из вариантов
}

struct Questions: Codable, Identifiable {
    var id: String          // "q1"
    var text: String        // "Какие типы данных..."
    var type: QuestionType  // open | select
    var topicId: String     // "t1"
    
    // для select вопросов (может быть nil у open)
    var options: [String]?
    var correctIndex: Int?
}
