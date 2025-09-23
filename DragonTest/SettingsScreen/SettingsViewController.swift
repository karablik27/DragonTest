//
//  SettingsViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

// TODO: Переделать под дизайн

import UIKit
import FirebaseAuth

final class SettingsViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки"
        
        setupBackground()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }
    
    private func setupBackground() {
        view.layer.sublayers?
            .filter { $0.name == "backgroundGradient" }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = "backgroundGradient"
        gradient.colors = [
            UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1).cgColor,
            UIColor(red: 206/255, green: 204/255, blue: 195/255, alpha: 1).cgColor,
            UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.25, 0.65, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.frame      = view.bounds
        gradient.zPosition  = -1000
        view.layer.insertSublayer(gradient, at: 0)
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
        
        let themeLabel = UILabel()
        themeLabel.text = "Тема"
        themeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let themeSegment = UISegmentedControl(items: ["Светлая", "Темная"])
        themeSegment.selectedSegmentIndex = 0
        let themeStack = UIStackView(arrangedSubviews: [themeLabel, themeSegment])
        themeStack.axis = .vertical
        themeStack.spacing = 6
        
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
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        contentStack.addArrangedSubview(nameField)
        contentStack.addArrangedSubview(tgField)
        contentStack.addArrangedSubview(loginField)
        contentStack.addArrangedSubview(passwordField)
        contentStack.addArrangedSubview(roleStack)
        contentStack.addArrangedSubview(langStack)
        contentStack.addArrangedSubview(themeStack)
        contentStack.addArrangedSubview(notifStack)
        contentStack.addArrangedSubview(logoutButton)
    }
    
    @objc private func logoutTapped() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("SignOut error:", error)
        }

        if let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.delegate as? SceneDelegate {

            let login = LoginViewController()
            let nav = UINavigationController(rootViewController: login)

            if let window = sceneDelegate.window {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.rootViewController = nav
                }
            }
        }
    }
}
