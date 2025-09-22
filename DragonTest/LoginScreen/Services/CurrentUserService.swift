//
//  CurrentUserService.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import Foundation

final class CurrentUserService: CurrentUserServiceProtocol {
    private let defaults = UserDefaults.standard
    private let userIdKey = "currentUserId"
    private let userRoleKey = "currentUserRole"

    var userId: String? {
        get { defaults.string(forKey: userIdKey) }
        set { defaults.setValue(newValue, forKey: userIdKey) }
    }

    var role: Role? {
        get {
            guard let raw = defaults.string(forKey: userRoleKey) else { return nil }
            return Role(rawValue: raw)
        }
        set {
            defaults.setValue(newValue?.rawValue, forKey: userRoleKey)
        }
    }

    func clear() {
        defaults.removeObject(forKey: userIdKey)
        defaults.removeObject(forKey: userRoleKey)
    }
}
