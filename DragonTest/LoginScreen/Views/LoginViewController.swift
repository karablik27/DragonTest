//
//  LoginViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 20.09.2025.
//

import UIKit

final class LoginViewController: UIViewController, UITextFieldDelegate {
    private var presenter: LoginViewOutput!

    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Вход в\nаккаунт"
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        return label
    }()

    private lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Почта"
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        tf.layer.cornerRadius = 8
        tf.textColor = .white
        tf.setLeftPaddingPoints(12)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        tf.returnKeyType = .next
        tf.delegate = self
        return tf
    }()

    private lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Пароль"
        tf.isSecureTextEntry = true
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        tf.layer.cornerRadius = 8
        tf.textColor = .white
        tf.setLeftPaddingPoints(12)
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        tf.returnKeyType = .next
        tf.delegate = self
        return tf
    }()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    private let rememberSwitch = UISwitch()

    private let rememberLabel: UILabel = {
        let l = UILabel()
        l.text = "Запомнить меня"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .white
        return l
    }()

    private lazy var loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Войти", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var signUpButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Регистрация"
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 150, bottom: 0, trailing: 0)

        let title = AttributedString("Регистрация", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ]))
        config.attributedTitle = title

        let btn = UIButton(configuration: config, primaryAction: nil)
        btn.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addTapToDismissKeyboard()
        presenter = LoginPresenter(
            view: self,
            authService: DependencyInjection.shared.authentication,
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
        // Удаляем старый слой если есть
        view.layer.sublayers?
            .filter { $0.name == "backgroundGradient" }
            .forEach { $0.removeFromSuperlayer() }

        // === Градиентный фон ===
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

        // === Stack ===
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            emailTextField,
            passwordTextField,
            makeRememberMeStack(),
            loginButton,
            makeSignUpStack()
        ])
        stack.axis = .vertical
        stack.spacing = 16

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func makeRememberMeStack() -> UIStackView {
        let s = UIStackView(arrangedSubviews: [rememberSwitch, rememberLabel])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 8
        return s
    }

    private func makeSignUpStack() -> UIStackView {
        let lbl = UILabel()
        lbl.text = "Нет аккаунта?"
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 14)

        let s = UIStackView(arrangedSubviews: [lbl, signUpButton])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 6
        s.distribution = .fillProportionally
        return s
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
    @objc private func loginTapped() {
        presenter.didTapLogin(
            email: emailTextField.text ?? "",
            password: passwordTextField.text ?? ""
        )
    }

    @objc private func signUpTapped() {
        presenter.didTapSignUp()
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

extension LoginViewController: LoginViewInput {
    func setLoading(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        signUpButton.isEnabled = !isLoading
        view.isUserInteractionEnabled = !isLoading
        // Добавить индикатор
    }
    
    func showError(_ message: String) {
        showAlert(title: "Ошибка", message: message)
    }
    
    func closeKeyboard() {
        view.endEditing(true)
    }
    
    func openMain() {
        if let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            let root = RootTabBarController()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                window.rootViewController = root
            }
            window.makeKeyAndVisible()
        }
    }
    
    func openSignUp() {
        let vc = SignUpViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}
