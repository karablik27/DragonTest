//
//  AuthenticationServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

protocol AuthenticationServiceProtocol {
    func createUser(email: String, password: String) async throws -> User
    func signInUser(email: String, password: String) async throws -> User
}
