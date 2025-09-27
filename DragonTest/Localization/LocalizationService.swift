//
//  LocalizationService.swift
//  DragonTest
//
//  Created by Карабельников Степан on 07.08.2025.
//

import Combine
import SwiftUI

final class LocalizationService: ObservableObject, Equatable {
    @Published var language: String = Localizer.selectedLanguage {
        didSet {
            objectWillChange.send()
        }
    }

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: .languageChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.language = Localizer.selectedLanguage
            }
    }

    static func == (lhs: LocalizationService, rhs: LocalizationService) -> Bool {
        lhs.language == rhs.language
    }

    func changeLanguage(to newLang: Language) {
        let languageCode = newLang == .russian ? "ru" : "en"
        Localizer.selectedLanguage = languageCode
        language = languageCode
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
} 