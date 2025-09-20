//
//  UserRole.swift
//  DragonTest
//
//  Created by Верховный Маг on 20.09.2025.
//

import Foundation

enum Role: String, Codable {
    case student = "Студент"
    case teacher = "Преподаватель"
}

enum Language: String, Codable {
    case russian = "Русский"
    case english = "English"
}

struct User: Codable {
    var id: UUID
    var image: String?
    var name: String
    var surname: String
    var lastname: String
    var email: String
    var password: String
    var telegramId: String
    var role: Role
    var language: Language
    var isNotificationEnabled: Bool
}
