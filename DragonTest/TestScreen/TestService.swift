//
//  TestService.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

//
//  TestService.swift
//  DragonTest
//

import Foundation
import FirebaseFirestore

enum CurrentUser {
    static let id = "Бля пока нет нахуй"
}

final class TestService: TestServiceProtocol {
    private let db = Firestore.firestore()

    // Показываем только тесты этого преподавателя
    func fetchTests(completion: @escaping (Result<[Test], Error>) -> Void) {
        db.collection("tests")
            .whereField("teacherId", isEqualTo: CurrentUser.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error)); return
                }
                let tests: [Test] = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Test.self)
                } ?? []
                completion(.success(tests))
            }
    }

    func createTest(title: String,
                    dragon: DragonKind,
                    questions: [Questions],
                    studentIds: [String] = [],
                    completion: @escaping (Result<Test, Error>) -> Void) {
        let test = Test(
            id: UUID().uuidString,
            title: title,
            dragonKind: dragon,
            questions: questions,
            teacherId: CurrentUser.id,
            studentIds: studentIds
        )
        saveTest(test) { result in
            switch result {
            case .success: completion(.success(test))
            case .failure(let err): completion(.failure(err))
            }
        }
    }

    func saveTest(_ test: Test, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("tests")
                .document(test.id)
                .setData(from: test) { error in
                    if let error = error { completion(.failure(error)) }
                    else { completion(.success(())) }
                }
        } catch {
            completion(.failure(error))
        }
    }
}
