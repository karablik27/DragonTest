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

        let profile = UINavigationController(rootViewController: MainViewController())
        profile.tabBarItem = UITabBarItem(title: "Профиль", image: UIImage(systemName: "person.crop.circle"), tag: 0)
        
        let test = UINavigationController(rootViewController: DragonSelectViewController())
        test.tabBarItem = UITabBarItem(title: "Тест", image: UIImage(named: "dragon.icon"), tag: 1)
        
        let settings = UINavigationController(rootViewController: MainViewController())
        settings.tabBarItem = UITabBarItem(title: "Настройки", image: UIImage(systemName: "gearshape"), tag: 2)

        viewControllers = [profile,test, settings]
        
        let appearance = UITabBarAppearance()
        

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 2.05, green: 1.65, blue: 0.72, alpha: 0.5)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 2.05, green: 1.65, blue: 0.72, alpha: 0.5)]
        
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
    }
}
