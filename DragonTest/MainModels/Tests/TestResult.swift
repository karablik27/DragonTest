//
//  TestResult.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

struct TestResult: Codable, Identifiable {
    var id: String          // studentId (или UUID результата)
    var testId: String      // ссылка на тест
    var studentId: String   // ссылка на ученика
    var score: Int          // набранные баллы
    var completed: Int      // сколько вопросов ответил (≤ 40)
    var capturedDragon: Bool // поймал ли дракона (если все правильно)
}
