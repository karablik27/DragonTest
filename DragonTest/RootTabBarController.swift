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

        let main = UINavigationController(rootViewController: MainViewController())
        main.tabBarItem = UITabBarItem(title: "Main", image: UIImage(systemName: "house"), tag: 0)

        let select = UINavigationController(rootViewController: DragonSelectViewController())
        select.tabBarItem = UITabBarItem(title: "Select", image: UIImage(systemName: "circle.grid.3x3"), tag: 1)

        viewControllers = [main, select]
    }
}
