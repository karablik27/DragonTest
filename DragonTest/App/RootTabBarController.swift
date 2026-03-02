//
//  RootTabBarController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 17.09.2025.
//

import UIKit

final class RootTabBarController: UITabBarController {
    private let profileVC = ProfileViewController()
    private let dragonSelectVC = DragonSelectViewController()
    private let settingsVC = SettingsViewController()
    private var didSetupAIRecoveryObserver = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let profile = UINavigationController(rootViewController: profileVC)
        profile.tabBarItem = UITabBarItem(title: "Профиль",
                                          image: UIImage(systemName: "person.crop.circle"),
                                          tag: 0)

        let test = UINavigationController(rootViewController: dragonSelectVC)
        test.tabBarItem = UITabBarItem(title: "Тесты",
                                       image: UIImage(named: "dragon.icon"),
                                       tag: 1)

        let settings = UINavigationController(rootViewController: settingsVC)
        settings.tabBarItem = UITabBarItem(title: "Настройки",
                                           image: UIImage(systemName: "gearshape"),
                                           tag: 2)

        viewControllers = [profile, test, settings]
        
        setupTabBarAppearance()
        
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (vc: RootTabBarController, previous: UITraitCollection) in
            vc.setupTabBarAppearance()
        }

        _ = dragonSelectVC.view
        dragonSelectVC.view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !didSetupAIRecoveryObserver {
            didSetupAIRecoveryObserver = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(scheduleAIRecovery),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
        }

        scheduleAIRecovery()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func scheduleAIRecovery() {
        Task {
            await AIReviewRecoveryCoordinator.shared.recoverPendingAIReviews()
        }
    }

    func preloadInitialData(timeout: TimeInterval = 2.2, completion: @escaping () -> Void) {
        var didComplete = false
        let finish: () -> Void = {
            guard !didComplete else { return }
            didComplete = true
            completion()
        }

        profileVC.prepareForInitialDataGate()
        profileVC.setInitialDataReadyHandler {
            finish()
        }

        profileVC.loadViewIfNeeded()
        _ = dragonSelectVC.view

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            finish()
        }
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
        
        appearance.backgroundEffect = UIBlurEffect(style: .regular)
        appearance.backgroundColor = UIColor.clear
        tabBar.scrollEdgeAppearance = appearance
        
        tabBar.standardAppearance = appearance
    }
}
