//
//  DragonTest.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//

// Question.swift
struct Question {
    let text: String
    let answers: [String]
    let correctIndex: Int
}

// DragonTest.swift
struct DragonTest {
    let id: String
    let dragon: DragonKind
    let title: String
    let totalQuestions: Int
    var completed: Int
    let questions: [Question]
}
