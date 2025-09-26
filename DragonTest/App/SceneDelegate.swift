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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        print("AUTH at launch, currentUser UID:", Auth.auth().currentUser?.uid as Any)
        
        if Auth.auth().currentUser == nil {
            let login = LoginViewController()
            let nav = UINavigationController(rootViewController: login)
            window.rootViewController = nav
        } else {
            window.rootViewController = RootTabBarController()
        }
        
        self.window = window
        window.makeKeyAndVisible()
        
        DispatchQueue.main.async {
            let preloadView = DragonPreviewView(frame: .zero)
            window.addSubview(preloadView)
            preloadView.isHidden = true

            for kind in [DragonKind.red, .green, .blue] {
                if let entity = DependencyInjection.shared.dragonCache.clone(for: kind, scale: [0.1,0.1,0.1]) {
                    preloadView.displayEntity(entity)
                }
            }

            preloadView.removeFromSuperview()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) { }

}

