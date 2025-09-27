//
//  SettingsViewProtocol.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit

protocol SettingsViewProtocol: AnyObject {
    func applyBackground()
    func setFields(name: String?, tg: String?, email: String?)
    func setRoleIndex(_ index: Int)
    func setThemeIndex(_ index: Int)
    func setNotifications(_ isOn: Bool)
    func setAvatar(_ image: UIImage)
    func setAvatarPlaceholder()
    func showAlert(title: String, message: String)
    func openLoginScreen()
    func reloadLayoutIfNeeded()
}
