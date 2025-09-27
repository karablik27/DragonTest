//
//  SettingsPresenterProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

protocol SettingsPresenterProtocol: AnyObject {
    func attach(view: SettingsViewProtocol)
    func viewDidLoad()
    func themeChanged(index: Int)
    func logoutTapped()
    func nameChanged(_ text: String)
    func telegramChanged(_ text: String)
    func emailChanged(_ text: String)
    func passwordChanged(_ text: String)
    func roleChanged(index: Int)
    func notificationsChanged(_ isOn: Bool)
    func didPickAvatar(_ image: UIImage)
}
