//
//  ResultStyle.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

import UIKit

enum ResultStyle {
    // Карточки / разделители
    static let cardFill     = UIColor.black.withAlphaComponent(0.18)
    static let stroke       = UIColor.white.withAlphaComponent(0.25).cgColor
    static let separator    = UIColor.white.withAlphaComponent(0.10)

    // Чипы
    static let pillNeutral  = UIColor.white.withAlphaComponent(0.20)
    static let pillNumberBG = UIColor.white.withAlphaComponent(0.30)
    static let pillBorder   = UIColor.white.withAlphaComponent(0.28).cgColor

    // Алиасы для совместимости
    static let pillNeutralBG: UIColor = pillNeutral
    static let pillAccentBGAlpha: CGFloat = 0.23
    static let whitePillBG   = UIColor.white.withAlphaComponent(0.92)
    static let whitePillText = UIColor.black

    // Акценты (общие)
    static let aiAccent      = UIColor.systemOrange
    static let teacherAccent = UIColor.systemBlue
    static let okAccent      = UIColor.systemGreen

    // ⚡️ Яркие заливки для плашек-оценок (НЕ стекло)
    static let aiScoreFill: UIColor = UIColor(red: 1.00, green: 0.53, blue: 0.08, alpha: 0.95)     // сочный оранжевый
    static let teacherScoreFill: UIColor = UIColor(red: 0.05, green: 0.43, blue: 0.93, alpha: 0.95) // сочный синий

    // Типографика
    static let questionFont = UIFont.systemFont(ofSize: 21, weight: .semibold)
    static let answerFont   = UIFont.systemFont(ofSize: 18, weight: .regular)
    static let sectionTitle = UIFont.systemFont(ofSize: 14, weight: .semibold)
    static let scoreFont    = UIFont.systemFont(ofSize: 17, weight: .bold)
    static let commentFont  = UIFont.systemFont(ofSize: 16, weight: .regular)

    // Радиусы
    static let cardRadius: CGFloat   = 22
    static let chipRadius: CGFloat   = 12
    static let answerRadius: CGFloat = 14
}
