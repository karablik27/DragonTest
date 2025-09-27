//
//  SessionServiceProtocol.swift
//  DragonTest
//
//  Created by Крючков Сергей on 23.09.2025.
//

protocol SessionServiceProtocol {
    func startSession(uid: String, deviceId: String, force: Bool) async throws -> String
    func endSession(uid: String, deviceId: String) async
}

enum SessionError: Error {
    case conflict
    case notAuthenticated
}
