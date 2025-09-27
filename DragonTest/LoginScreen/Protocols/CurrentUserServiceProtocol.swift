//
//  CurrentUserServiceProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

protocol CurrentUserServiceProtocol {
    var userId: String? { get set }
    var role: Role? { get set }
    func clear()
    func getCurrentUser() async throws -> User?
}
