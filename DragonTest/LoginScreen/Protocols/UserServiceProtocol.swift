//
//  UserServiceProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

protocol UserServiceProtocol {
    func saveUser(_ user: User) async throws
    func updateUser(_ update: UserUpdate) async throws
    func updateEmail(_ newEmail: String) async throws
    func updatePassword(_ newPassword: String) async throws
    func fetchUser(uid: String) async throws -> User
    func fetchStudentsForTests(for test: Test) async throws -> [User]
}
