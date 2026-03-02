//
//  SceneDelegate.swift
//  DragonTest
//
//  Created by Карабельников Степан on 16.09.2025.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        let launchVC = LaunchViewController()
        window.rootViewController = launchVC
        self.window = window
        window.makeKeyAndVisible()
        ThemeManager.shared.applyCurrentTheme()

        // Предзагрузка драконов
        DispatchQueue.main.async {
            let preloadView = DragonPreviewView(frame: .zero)
            window.addSubview(preloadView)
            preloadView.isHidden = true

            for kind in [DragonKind.red, .green, .blue] {
                _ = DependencyInjection.shared.dragonCache.clone(
                    for: kind,
                    scale: [0.1, 0.1, 0.1]
                )
            }

            preloadView.removeFromSuperview()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }

                Task {
                    if let user = Auth.auth().currentUser {
                        do {
                            try await user.reload()
                        } catch {
                            // если не смогли обновить — кидаем на логин
                            await MainActor.run {
                                let login = LoginViewController()
                                let nav = UINavigationController(rootViewController: login)
                                self.transitionRoot(to: nav, duration: 0.8)
                            }
                            return
                        }

                        if user.isEmailVerified {
                            await MainActor.run {
                                self.transitionToMain(preloadData: true, duration: 0.8)
                            }
                        } else {
                            // пользователь есть, но почта не подтверждена — считаем, что он не залогинен
                            await MainActor.run {
                                let login = LoginViewController()
                                let nav = UINavigationController(rootViewController: login)
                                self.transitionRoot(to: nav, duration: 0.8)
                            }
                        }
                    } else {
                        await MainActor.run {
                            let login = LoginViewController()
                            let nav = UINavigationController(rootViewController: login)
                            self.transitionRoot(to: nav, duration: 0.8)
                        }
                    }
                }
            }
        }
    }

    func transitionToMain(preloadData: Bool = true, duration: TimeInterval = 0.35) {
        guard window != nil else { return }
        let root = RootTabBarController()
        let showRoot = { [weak self] in
            self?.transitionRoot(to: root, duration: duration)
        }

        if preloadData {
            root.preloadInitialData {
                showRoot()
            }
        } else {
            showRoot()
        }
    }

    private func transitionRoot(to rootVC: UIViewController, duration: TimeInterval) {
        guard let window else { return }
        UIView.transition(with: window,
                          duration: duration,
                          options: .transitionCrossDissolve,
                          animations: {
            window.rootViewController = rootVC
        }, completion: { _ in
            ThemeManager.shared.applyCurrentTheme()
        })
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
