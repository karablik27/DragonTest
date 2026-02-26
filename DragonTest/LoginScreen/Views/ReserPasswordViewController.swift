//
//  ReserPasswordViewController.swift
//  DragonTest
//
//  Created by Sergey on 26.02.2026.
//

import UIKit

final class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    private var presenter: ResetPasswordViewOutput!

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Сброс пароля"
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
        tf.returnKeyType = .done
        tf.delegate = self
        return tf
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Отправить", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        addTapToDismissKeyboard()

        presenter = ResetPasswordPresenter(
            view: self,
            authService: DependencyInjection.shared.authentication
        )
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }

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

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            emailTextField,
            sendButton
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        presenter.didTapSend(email: emailTextField.text ?? "")
        return true
    }

    @objc private func sendTapped() {
        presenter.didTapSend(email: emailTextField.text ?? "")
    }

    @objc private func backTapped() {
        presenter.didTapBack()
    }

    @objc private func handleTapToDismiss() {
        view.endEditing(true)
    }

    private func showAlert(title: String, message: String, onOk: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOk?() })
        present(alert, animated: true)
    }
}

extension ResetPasswordViewController: ResetPasswordViewInput {
    func setLoading(_ isLoading: Bool) {
        sendButton.isEnabled = !isLoading
        view.isUserInteractionEnabled = !isLoading
    }

    func showError(_ message: String) {
        showAlert(title: "Ошибка", message: message)
    }

    func showSuccessAndClose(_ message: String) {
        showAlert(title: "Готово", message: message) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    func closeKeyboard() {
        view.endEditing(true)
    }

    func backToLogin() {
        dismiss(animated: true)
    }
}
