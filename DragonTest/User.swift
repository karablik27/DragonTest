//
//  UserRole.swift
//  DragonTest
//
//  Created by Верховный Маг on 20.09.2025.
//

import Foundation
import FirebaseAuth

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
    
    init(user: FirebaseAuth.User) {
            self.id = UUID()
            self.image = nil
            self.name = ""
            self.surname = ""
            self.lastname = ""
            self.email = user.email ?? ""
            self.password = ""
            self.telegramId = ""
            self.role = .student
            self.language = .russian
            self.isNotificationEnabled = true
        }
}
