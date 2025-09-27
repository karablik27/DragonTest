//
//  ThemeManager.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit

enum AppTheme: Int, Codable, CaseIterable {
    case system = 0
    case light  = 1
    case dark   = 2
}

extension Notification.Name {
    static let appThemeDidChange = Notification.Name("appThemeDidChange")
}

final class ThemeManager {
    static let shared = ThemeManager()
    private let key = "app_theme_pref"

    var current: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            apply(newValue)
            NotificationCenter.default.post(name: .appThemeDidChange, object: nil)
        }
    }

    private init() { apply(current) }

    private func apply(_ theme: AppTheme) {
        let style: UIUserInterfaceStyle
        switch theme {
        case .system: style = .unspecified
        case .light:  style = .light
        case .dark:   style = .dark
        }
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}
