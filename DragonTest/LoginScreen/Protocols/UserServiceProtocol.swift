//
//  UserServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

protocol UserServiceProtocol {
    func saveUser(_ user: User) async throws
    func fetchUser(uid: String) async throws -> User
    func fetchStudentsForTests(for test: Test) async throws -> [User]
}
