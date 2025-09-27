//
//  TestServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

protocol TestServiceProtocol {
    func fetchTests() async throws -> [Test]

    func createTest(title: String,
                    dragon: DragonKind,
                    questions: [Questions],
                    studentIds: [String],
                    completion: @escaping (Result<Test, Error>) -> Void)

    func saveTest(_ test: Test, completion: @escaping (Result<Void, Error>) -> Void)
}
