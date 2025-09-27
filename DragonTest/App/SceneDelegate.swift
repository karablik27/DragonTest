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

                let rootVC: UIViewController
                if Auth.auth().currentUser == nil {
                    let login = LoginViewController()
                    let nav = UINavigationController(rootViewController: login)
                    rootVC = nav
                } else {
                    rootVC = RootTabBarController()
                }

                UIView.transition(with: window,
                                  duration: 0.8,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    window.rootViewController = rootVC
                })
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
