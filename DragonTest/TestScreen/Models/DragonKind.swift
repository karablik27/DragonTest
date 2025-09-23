//
//  DragonKind.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit

enum DragonKind: CaseIterable, Codable {
    case red, green, blue

    var fileName: String {
        switch self {
        case .red:   return "Dragon_Red"
        case .green: return "Dragon_Green"
        case .blue:  return "Dragon_Blue"
        }
    }

    var title: String {
        switch self {
        case .red:   return "Red Dragon"
        case .green: return "Green Dragon"
        case .blue:  return "Blue Dragon"
        }
    }

    /// Градиент фона под каждого дракона
    var gradientColors: [CGColor] {
        switch self {
        case .red:
            return [
                UIColor(red: 0.96, green: 0.50, blue: 0.77, alpha: 0.5).cgColor,
                UIColor(red: 1.66, green: 0.69, blue: 0.63, alpha: 0.5).cgColor,
                UIColor(red: 1.63, green: 1.30, blue: 0.47, alpha: 0.5).cgColor
            ]
        case .green:
            return [
                UIColor(red: 1.04, green: 1.14, blue: 0.57, alpha: 0.5).cgColor,
                UIColor(red: 0.87, green: 1.10, blue: 0.71, alpha: 0.5).cgColor,
                UIColor(red: 2.26, green: 1.91, blue: 0.96, alpha: 0.5).cgColor
            ]
        case .blue:
            return [
                UIColor(red: 0.57, green: 0.60, blue: 1.21, alpha: 0.5).cgColor,
                UIColor(red: 1.07, green: 1.08, blue: 1.49, alpha: 0.5).cgColor,
                UIColor(red: 2.05, green: 1.65, blue: 0.72, alpha: 0.5).cgColor
            ]
        }
    }
    
    func getFirstColor(colors:[CGColor]) -> CGColor {
        let color = colors[0]
        return color
    }
}
