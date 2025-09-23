//
//  TestService.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//


import Foundation
import FirebaseFirestore


final class TestService: TestServiceProtocol {
    private let dataBase: Firestore
    private let currentUser: CurrentUserServiceProtocol
    
    init(dataBase: Firestore, currentUser: CurrentUserServiceProtocol) {
        self.dataBase = dataBase
        self.currentUser = currentUser
    }

    func fetchTests() async throws -> [Test] {
        let snapshot = try await DependencyInjection.shared.dataBase.collection("tests")
            .whereField("teacherId", isEqualTo: currentUser.userId ?? "")
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Test.self) }
    }


    func createTest(title: String, dragon: DragonKind, questions: [Questions],
                    studentIds: [String] = [],
                    completion: @escaping (Result<Test, Error>
                    ) -> Void) {
        guard let teacherId = currentUser.userId else {
            completion(.failure(NSError(domain: "TestService",
                                        code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Нет userId у текущего пользователя"])))
            return
        }

        let test = Test(
            id: UUID().uuidString,
            title: title,
            dragonKind: dragon,
            questions: questions,
            teacherId: teacherId,
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
            try dataBase.collection("tests")
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
