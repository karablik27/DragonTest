//
//  TestServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

protocol TestServiceProtocol {
    /// Получить тесты, созданные текущим преподавателем
    func fetchTests(completion: @escaping (Result<[Test], Error>) -> Void)

    /// Создать тест и сохранить в Firestore
    func createTest(title: String,
                    dragon: DragonKind,
                    questions: [Questions],
                    studentIds: [String],
                    completion: @escaping (Result<Test, Error>) -> Void)

    /// Сохранить готовый тест (если его уже собрали где-то ещё)
    func saveTest(_ test: Test, completion: @escaping (Result<Void, Error>) -> Void)
}
