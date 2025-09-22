//
//  MockTestService.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//

import UIKit

// MockTestService.swift
final class MockTestService {
    static let shared = MockTestService()
    private init() {}
    
    private var tests: [DragonTest] = [
        DragonTest(
            id: "abc123",
            dragon: .red,
            title: "Огненное испытание",
            totalQuestions: 3,
            completed: 0,
            questions: [
                Question(text: "Какого цвета этот дракон?", answers: ["Красный", "Зелёный", "Синий"], correctIndex: 0),
                Question(text: "Чем дышит дракон?", answers: ["Огнём", "Льдом", "Водой"], correctIndex: 0),
                Question(text: "Где живёт дракон?", answers: ["Пещера", "Озеро", "Лес"], correctIndex: 0)
            ]
        )
    ]
    
    func randomTest() -> DragonTest {
        let kind = DragonKind.allCases.randomElement()!
        return DragonTest(
            id: UUID().uuidString,
            dragon: kind,
            title: "\(kind.title) Quiz",
            totalQuestions: 3,
            completed: 0,
            questions: [
                Question(text: "Вопрос 1", answers: ["A", "B", "C"], correctIndex: 0),
                Question(text: "Вопрос 2", answers: ["A", "B", "C"], correctIndex: 1),
                Question(text: "Вопрос 3", answers: ["A", "B", "C"], correctIndex: 2)
            ]
        )
    }
    
    func test(by code: String) -> DragonTest? {
        return tests.first { $0.id == code }
    }
}
