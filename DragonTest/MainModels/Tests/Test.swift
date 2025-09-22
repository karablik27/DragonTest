//
//  Test.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//


struct Test: Codable, Identifiable {
    var id: String              // UUID
    var title: String           // "Коллоквиум №1"
    var dragonKind: DragonKind  // red / green / blue
    var questions: [Questions]   // ровно 40 вопросов
    var teacherId: String       // id преподавателя
    var studentIds: [String]    // список id студентов, приглашённых к тесту
}



