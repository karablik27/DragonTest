//
//  RootTabBarController.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit

final class RootTabBarController: UITabBarController {
    
    private var profileTab: UINavigationController!
    private var testTab: UINavigationController!
    private var settingsTab: UINavigationController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileTab = UINavigationController(rootViewController: ProfileViewController())
        profileTab.tabBarItem = UITabBarItem(title: "tabbar.profile".localized,
                                          image: UIImage(systemName: "person.crop.circle"),
                                          tag: 0)
        
        let dragonSelectVC = DragonSelectViewController()
        testTab = UINavigationController(rootViewController: dragonSelectVC)
        testTab.tabBarItem = UITabBarItem(title: "tabbar.tests".localized,
                                       image: UIImage(named: "dragon.icon"),
                                       tag: 1)
        
        settingsTab = UINavigationController(rootViewController: SettingsViewController())
        settingsTab.tabBarItem = UITabBarItem(title: "tabbar.settings".localized,
                                           image: UIImage(systemName: "gearshape"),
                                           tag: 2)

        viewControllers = [profileTab, testTab, settingsTab]
        
        setupTabBarAppearance()
        setupAutoLocalization()
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (vc: RootTabBarController, previous: UITraitCollection) in
            vc.setupTabBarAppearance()
        }

        _ = dragonSelectVC.view
        dragonSelectVC.view.layoutIfNeeded()
    }
    
    override func updateLocalization() {
        super.updateLocalization()
        
        // Обновляем названия табов
        profileTab.tabBarItem.title = "tabbar.profile".localized
        testTab.tabBarItem.title = "tabbar.tests".localized
        settingsTab.tabBarItem.title = "tabbar.settings".localized
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
        
        if #available(iOS 15.0, *) {
            appearance.backgroundEffect = UIBlurEffect(style: .regular)
            appearance.backgroundColor = UIColor.clear
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.standardAppearance = appearance
    }
}
