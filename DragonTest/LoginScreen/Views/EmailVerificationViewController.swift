//
//  EmailVerificationViewController.swift
//  DragonTest
//
//  Created by Sergey on 02.03.2026.
//

import UIKit
import FirebaseAuth

final class EmailVerificationViewController: UIViewController {
    
    private let pendingUser: User
    private var resendTimer: Timer?
    private var resendRemainingSeconds: Int = 0
    
    // MARK: - UI
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Подтверждение почты"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    private let checkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Проверить", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .black
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }()
    
    private let resendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Прислать письмо заново", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return btn
    }()
    
    private let backButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseForegroundColor = .white
        config.image = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold))
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        config.background.strokeColor = UIColor.white.withAlphaComponent(0.25)
        config.background.strokeWidth = 1
        config.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        return UIButton(configuration: config)
    }()
    
    // MARK: - Init
    
    init(user: User) {
        self.pendingUser = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        startResendCooldown(seconds: 90)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
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
        
        messageLabel.text = """
        Перейдите по ссылке, которая отправлена на почту:
        \(pendingUser.email)
        """
        
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            messageLabel,
            checkButton,
            resendButton
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
        
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.widthAnchor.constraint(equalToConstant: 52),
            backButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    private func setupActions() {
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    private func startResendCooldown(seconds: Int = 90) {
        resendTimer?.invalidate()
        resendRemainingSeconds = seconds
        updateResendButtonState()

        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.resendRemainingSeconds -= 1
            if self.resendRemainingSeconds <= 0 {
                timer.invalidate()
                self.resendTimer = nil
                self.resendRemainingSeconds = 0
            }
            self.updateResendButtonState()
        }
    }

    private func updateResendButtonState() {
        if resendRemainingSeconds > 0 {
            resendButton.isEnabled = false
            let minutes = resendRemainingSeconds / 60
            let seconds = resendRemainingSeconds % 60
            let timeString = String(format: "%01d:%02d", minutes, seconds)

            UIView.performWithoutAnimation {
                self.resendButton.setTitle("Прислать письмо заново (\(timeString))", for: .normal)
                self.resendButton.layoutIfNeeded()
            }

            resendButton.alpha = 0.6
        } else {
            resendButton.isEnabled = true

            UIView.performWithoutAnimation {
                self.resendButton.setTitle("Прислать письмо заново", for: .normal)
                self.resendButton.layoutIfNeeded()
            }

            resendButton.alpha = 1.0
        }
    }
    
    @objc private func checkTapped() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Ошибка", message: "Сессия истекла. Войдите заново.")
            dismiss(animated: true)
            return
        }
        
        Task {
            do {
                try await user.reload()
                
                guard user.isEmailVerified else {
                    await MainActor.run {
                        self.showAlert(
                            title: "Почта не подтверждена",
                            message: "Перейдите по ссылке из письма и попробуйте ещё раз."
                        )
                    }
                    return
                }
                
                let deviceId = DeviceIdProvider.shared.deviceId
                
                do {
                    _ = try await DependencyInjection.shared.sessionService.startSession(
                        uid: user.uid,
                        deviceId: deviceId,
                        force: false
                    )
                } catch {
                    await MainActor.run {
                        self.showAlert(
                            title: "Аккаунт уже активен",
                            message: "Аккаунт уже активен на другом устройстве. Пожалуйста, завершите сессию на другом устройстве."
                        )
                    }
                    return
                }
                
                DependencyInjection.shared.currentUser.userId = pendingUser.id
                DependencyInjection.shared.currentUser.role = pendingUser.role
                
                await MainActor.run {
                    
                    self.resendTimer?.invalidate()
                    self.resendTimer = nil

                    
                    self.checkButton.isEnabled = false
                    self.resendButton.isEnabled = false
                    self.backButton.isEnabled = false

                    
                    if let sceneDelegate = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.delegate as? SceneDelegate {
                        sceneDelegate.transitionToMain(preloadData: true, duration: 0.35)
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(
                        title: "Ошибка",
                        message: "Не удалось проверить статус. Попробуйте ещё раз."
                    )
                }
            }
        }
    }
    
    @objc private func resendTapped() {
        guard resendRemainingSeconds == 0 else { return }
        
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Ошибка", message: "Сессия истекла. Войдите заново.")
            dismiss(animated: true)
            return
        }
        
        Task {
            do {
                try await user.sendEmailVerification()
                await MainActor.run {
                    self.showAlert(
                        title: "Письмо отправлено",
                        message: "Новое письмо с подтверждением отправлено на \(pendingUser.email)."
                    )
                    self.startResendCooldown(seconds: 90)
                }
            } catch {
                await MainActor.run {
                    self.showAlert(
                        title: "Ошибка",
                        message: "Не удалось отправить письмо. Попробуйте позже."
                    )
                }
            }
        }
    }
    
    @objc private func backTapped() {
        let alert = UIAlertController(
            title: "Изменить данные?",
            message: "",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "ОК", style: .destructive) { [weak self] _ in
            self?.deleteCurrentAuthUserAndDismiss()
        })
        present(alert, animated: true)
    }

    private func deleteCurrentAuthUserAndDismiss() {
        resendTimer?.invalidate()
        resendTimer = nil

        Task {
            // Пытаемся удалить свежесозданного пользователя
            if let user = Auth.auth().currentUser {
                do {
                    try await user.delete()
                } catch {
                    // Если удалить не получилось (например, Firebase потребовал re-auth),
                    // хотя бы вылогиниваемся, чтобы не автозаходило в приложение
                }
            }

            try? Auth.auth().signOut()

            await MainActor.run {
                self.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func openMain() {
        if let sceneDelegate = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            sceneDelegate.transitionToMain(preloadData: true, duration: 0.35)
            window.makeKeyAndVisible()
        } else {
            dismiss(animated: true)
        }
    }
}
