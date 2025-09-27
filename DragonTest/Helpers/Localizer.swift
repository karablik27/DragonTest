//
//  Localizer.swift
//  DragonTest
//
//  Created by Карабельников Степан on 07.08.2025.
//

import Foundation

class Localizer {
    private static let languageKey = "selectedLanguage"

    static var selectedLanguage: String {
        get {
            if let saved = UserDefaults.standard.string(forKey: languageKey) {
                return saved
            } else {
                return Locale.current.language.languageCode?.identifier ?? "en"
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: languageKey)
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    static func localizedString(for key: String) -> String {
        let currentLanguage = DependencyInjection.shared.localizationService.language
        
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: bundle, comment: "")
        } else {
            return NSLocalizedString(key, bundle: .main, comment: "")
        }
    }
}

extension String {
    var localized: String {
        _ = DependencyInjection.shared.localizationService.language
        return Localizer.localizedString(for: self)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
} 