//
//  RootTabBarController.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let profile = UINavigationController(rootViewController: ProfileViewController())
        profile.tabBarItem = UITabBarItem(title: "Профиль",
                                          image: UIImage(systemName: "person.crop.circle"),
                                          tag: 0)
        
        let test = UINavigationController(rootViewController: DragonSelectViewController())
        test.tabBarItem = UITabBarItem(title: "Тесты",
                                       image: UIImage(named: "dragon.icon"),
                                       tag: 1)
        
        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(title: "Настройки",
                                           image: UIImage(systemName: "gearshape"),
                                           tag: 2)

        viewControllers = [profile, test, settings]
        
        setupTabBarAppearance()
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        let selectedColor = UIColor(red: 2.05, green: 1.65, blue: 0.72, alpha: 1.0)
        let normalColor: UIColor = {
            if traitCollection.userInterfaceStyle == .dark {
                return .white
            } else {
                return .black
            }
        }()
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        
        tabBar.standardAppearance = appearance
    }
    
    // Чтобы обновлять цвета при смене темы
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            setupTabBarAppearance()
        }
    }
}

