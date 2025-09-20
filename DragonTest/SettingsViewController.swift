//
//  SettingsViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

// TODO: Переделать под дизайн

import UIKit

final class SettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        title = "Настройки"
        
        setupLayout()
        addProfileSettings()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    // MARK: - Profile Settings
    private func addProfileSettings() {
        
        func makeField(title: String, placeholder: String, isSecure: Bool = false) -> UIStackView {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 14, weight: .medium)
            
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.borderStyle = .roundedRect
            textField.isSecureTextEntry = isSecure
            
            let stack = UIStackView(arrangedSubviews: [label, textField])
            stack.axis = .vertical
            stack.spacing = 6
            return stack
        }
    
        let nameField = makeField(title: "Имя пользователя", placeholder: "Введите имя")
        let tgField = makeField(title: "Телеграмм", placeholder: "Введите телеграмм")
        let loginField = makeField(title: "Логин", placeholder: "example@mail.com")
        let passwordField = makeField(title: "Пароль", placeholder: "Введите пароль", isSecure: true)
        
        let roleLabel = UILabel()
        roleLabel.text = "Роль"
        roleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let roleSegment = UISegmentedControl(items: ["Ученик", "Учитель"])
        roleSegment.selectedSegmentIndex = 0
        let roleStack = UIStackView(arrangedSubviews: [roleLabel, roleSegment])
        roleStack.axis = .vertical
        roleStack.spacing = 6
        
        let langLabel = UILabel()
        langLabel.text = "Язык"
        langLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let langSegment = UISegmentedControl(items: ["Русский", "English"])
        langSegment.selectedSegmentIndex = 0
        let langStack = UIStackView(arrangedSubviews: [langLabel, langSegment])
        langStack.axis = .vertical
        langStack.spacing = 6
        
        let notifLabel = UILabel()
        notifLabel.text = "Уведомления"
        notifLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let notifSwitch = UISwitch()
        notifSwitch.isOn = true
        let notifStack = UIStackView(arrangedSubviews: [notifLabel, notifSwitch])
        notifStack.axis = .horizontal
        notifStack.alignment = .center
        notifStack.spacing = 12
        
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Выйти", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.layer.cornerRadius = 22
        logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        contentStack.addArrangedSubview(nameField)
        contentStack.addArrangedSubview(tgField)
        contentStack.addArrangedSubview(loginField)
        contentStack.addArrangedSubview(passwordField)
        contentStack.addArrangedSubview(roleStack)
        contentStack.addArrangedSubview(langStack)
        contentStack.addArrangedSubview(notifStack)
        contentStack.addArrangedSubview(logoutButton)
    }
}
