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
    var id: String
    var image: String?
    var name: String
    var surname: String
    var lastname: String
    var email: String
    var telegramId: String
    var role: Role
    var language: Language
    var isNotificationEnabled: Bool
    
    init(
        firebaseUser: FirebaseAuth.User,
        name: String = "",
        surname: String = "",
        lastname: String = "",
        telegramId: String = "",
        role: Role = .student,
        language: Language = .russian,
        isNotificationEnabled: Bool = true
    ) {
        self.id = firebaseUser.uid
        self.image = nil
        self.name = name
        self.surname = surname
        self.lastname = lastname
        self.email = firebaseUser.email ?? ""
        self.telegramId = telegramId
        self.role = role
        self.language = language
        self.isNotificationEnabled = isNotificationEnabled
    }
}
