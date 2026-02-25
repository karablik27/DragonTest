//
//  SignUpViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 20.09.2025.
//

import UIKit

final class SignUpViewController: UIViewController, UITextFieldDelegate {
    private var presenter: SignUpViewOutput!
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Регистрация"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        return label
    }()

    private func makeTextField(placeholder: String, isSecure: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = isSecure
        tf.autocapitalizationType = .none
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        tf.layer.cornerRadius = 8
        tf.textColor = .white
        tf.setLeftPaddingPoints(12)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        tf.delegate = self
        return tf
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField: surnameTextField.becomeFirstResponder()
        case surnameTextField: lastnameTextField.becomeFirstResponder()
        case lastnameTextField: emailTextField.becomeFirstResponder()
        case emailTextField: passwordTextField.becomeFirstResponder()
        case passwordTextField: telegramIdTextField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }

    private lazy var nameTextField       = makeTextField(placeholder: "Имя")
    private lazy var surnameTextField    = makeTextField(placeholder: "Фамилия")
    private lazy var lastnameTextField   = makeTextField(placeholder: "Отчество")
    private lazy var emailTextField      = makeTextField(placeholder: "Почта")
    private lazy var passwordTextField   = makeTextField(placeholder: "Пароль", isSecure: true)
    private lazy var telegramIdTextField = makeTextField(placeholder: "Telegram ID")

    private lazy var signUpButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Зарегистрироваться", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        addTapToDismissKeyboard()
        presenter = SignUpPresenter(
            view: self,
            authService: DependencyInjection.shared.authentication,
            userService: DependencyInjection.shared.userService
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }

    // MARK: - Setup
    private func setupUI() {
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

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.alpha = 0.5
        view.addSubview(blur)
        view.sendSubviewToBack(blur)
        
        nameTextField.returnKeyType       = .next
        surnameTextField.returnKeyType    = .next
        lastnameTextField.returnKeyType   = .next
        emailTextField.returnKeyType      = .next
        passwordTextField.returnKeyType   = .next
        telegramIdTextField.returnKeyType = .done

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            nameTextField,
            surnameTextField,
            lastnameTextField,
            emailTextField,
            passwordTextField,
            telegramIdTextField,
            signUpButton
        ])
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .oneTimeCode    
        passwordTextField.autocorrectionType = .no
        passwordTextField.spellCheckingType = .no
        passwordTextField.smartQuotesType = .no
        passwordTextField.smartDashesType = .no
        passwordTextField.smartInsertDeleteType = .no
        
        stack.axis = .vertical
        stack.spacing = 12

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigation() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }
    
    private func addTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func signUpTapped() {
        guard
            let name = nameTextField.text, !name.isEmpty,
            let surname = surnameTextField.text, !surname.isEmpty,
            let lastname = lastnameTextField.text, !lastname.isEmpty,
            let email = emailTextField.text, !email.isEmpty,
            let password = passwordTextField.text, !password.isEmpty,
            let telegramId = telegramIdTextField.text
        else {
            showAlert(title: "Ошибка", message: "Заполните все поля")
            return
        }
        
        presenter.didTapSignUp(
            name: name,
            surname: surname,
            lastname: lastname,
            email: email,
            password: password,
            telegramId: telegramId,
            role: .student
        )
    }
    
    @objc private func backTapped() {
        presenter.didTapBack()
    }
    
    @objc private func handleTapToDismiss() {
        view.endEditing(true)
    }
}

// MARK: - Padding for TextField
private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

extension SignUpViewController: SignUpViewInput {
    func setLoading(_ isLoading: Bool) {
        signUpButton.isEnabled = !isLoading
        view.isUserInteractionEnabled = !isLoading
    }

    func showError(_ message: String) {
        showAlert(title: "Ошибка регистрации", message: message)
    }

    func showSuccess() {
    }

    func openMain() {
        if let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            setLoading(true)
            sceneDelegate.transitionToMain(preloadData: true, duration: 0.35)
            window.makeKeyAndVisible()
        } else {
            setLoading(false)
        }
    }

    func backToLogin() {
        dismiss(animated: true)
    }
}
