//
//  SettingsViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

import Photos
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Theme

enum AppTheme: Int, Codable, CaseIterable {
    case system = 0
    case light  = 1
    case dark   = 2
}

extension Notification.Name {
    static let appThemeDidChange = Notification.Name("appThemeDidChange")
}

final class ThemeManager {
    static let shared = ThemeManager()
    private let key = "app_theme_pref"

    var current: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .system }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            apply(newValue)
            NotificationCenter.default.post(name: .appThemeDidChange, object: nil)
        }
    }

    private init() { apply(current) }

    private func apply(_ theme: AppTheme) {
        let style: UIUserInterfaceStyle
        switch theme {
        case .system: style = .unspecified
        case .light:  style = .light
        case .dark:   style = .dark
        }
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

// MARK: - Glass UI

final class SettingsGlassCard: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let border = CAShapeLayer()
    private let radius: CGFloat

    init(radius: CGFloat = 16) {
        self.radius = radius
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        border.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }
}

final class SettingsGlassTextField: UIView {
    let textField = UITextField()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let border = CAShapeLayer()
    private let radius: CGFloat = 12

    var text: String? { get { textField.text } set { textField.text = newValue } }

    init(placeholder: String, isSecure: Bool = false, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        textField.translatesAutoresizingMaskIntoConstraints = false
                textField.backgroundColor = .clear
                textField.borderStyle = .none
                textField.placeholder = placeholder
                textField.isSecureTextEntry = isSecure
                textField.keyboardType = keyboard
                textField.clearButtonMode = .whileEditing
                textField.autocapitalizationType = .none
                textField.font = .systemFont(ofSize: 14)
        
        addSubview(textField)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        border.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }
}

// MARK: - SettingsViewController

final class SettingsViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var headerView: UIView!
    
    private let userService: UserServiceProtocol = UserService(dataBase: Firestore.firestore())
    
    private let avatarImageView = UIImageView()
    private let profilePhotosCollection = "profilePhoto"
    
    private var userDataTask: Task<User?, Never> = Task { nil }

    // MARK: - Controls
    private weak var themeSegment: UISegmentedControl?
    private weak var roleSegment: UISegmentedControl?
    private weak var langSegment: UISegmentedControl?
    private weak var notifSwitch: UISwitch?

    // MARK: - Fields
    private let nameField = SettingsGlassTextField(placeholder: "Введите имя")
    private let tgField = SettingsGlassTextField(placeholder: "@username")
    private let emailField = SettingsGlassTextField(
        placeholder: "example@mail.com",
        isSecure: false,
        keyboard: .emailAddress
    )
    private let passwordField = SettingsGlassTextField(
        placeholder: "Введите новый пароль",
        isSecure: true,
        keyboard: .default
    )

    private var allowTelegramEditing = false

    // MARK: - Init
    override init(nibName: String? = nil, bundle: Bundle? = nil) {
        super.init(nibName: nibName, bundle: bundle)
        userDataTask = loadUserData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        userDataTask = loadUserData()
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupLayout()
        buildForm()
        setupTelegramInteractions()
        fillFields()
        loadOrCreateProfilePhoto()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .appThemeDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Data Loading
    private func loadUserData() -> Task<User?, Never> {
        guard let uid = Auth.auth().currentUser?.uid else { return Task { nil } }
        return Task { [weak self] in
            do { return try await self?.userService.fetchUser(uid: uid) }
            catch {
                await MainActor.run {
                    self?.showAlert(title: "Ошибка", message: "Не удалось загрузить профиль")
                }
                return nil
            }
        }
    }

    // MARK: - Layout
    private func setupLayout() {
            headerView = buildHeader()
            view.addSubview(headerView)
            view.addSubview(scrollView)

            scrollView.backgroundColor = .clear
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.alwaysBounceVertical = true
            headerView.translatesAutoresizingMaskIntoConstraints = false
            contentStack.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -24),
                headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

                scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            scrollView.addSubview(contentStack)
            contentStack.axis = .vertical
            contentStack.spacing = 13

            NSLayoutConstraint.activate([
                contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 0),
                contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
                contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
                contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),

                contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
            ])
        }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupBackground()
    }

    // MARK: - Data
    
    // MARK: - Header
    private func buildHeader() -> UIView {
        let container = UIView()

        let usernameLabel = UILabel()
        usernameLabel.text = "Настройки"
        usernameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        usernameLabel.textColor = .label

        let textStack = UIStackView(arrangedSubviews: [usernameLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.masksToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tap)

        let rightStack = UIStackView(arrangedSubviews: [avatarImageView])
        rightStack.axis = .horizontal
        rightStack.alignment = .center
        rightStack.spacing = 12

        let hStack = UIStackView(arrangedSubviews: [textStack, UIView(), rightStack])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8

        container.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }


    // MARK: - Layout & Background
    
    

    private func setupBackground() {
        view.layer.sublayers?.filter { $0.name == "backgroundGradient" }.forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        
        gradient.name = "backgroundGradient"
        
        gradient.colors = [
            UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1).cgColor,
            UIColor(red: 206/255, green: 204/255, blue: 195/255, alpha: 1).cgColor,
            UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1).cgColor
        ]
        
        gradient.locations = [0.0, 0.25, 0.65, 1.0] as [NSNumber]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        gradient.zPosition = -1000
        
        view.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - Form

    private func buildForm() {
        let profileCard = SettingsGlassCard()
        let profileStack = UIStackView()
        profileStack.axis = .vertical
        profileStack.spacing = 10

        func fieldRow(title: String, field: SettingsGlassTextField, action: Selector?) -> UIView {
            let t = UILabel()
            t.text = title
            t.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            t.textColor = .label

            if let action { field.textField.addTarget(self, action: action, for: .editingDidEnd) }

            let v = UIStackView(arrangedSubviews: [t, field])
            v.axis = .vertical
            v.spacing = 6
            return v
        }

        [ fieldRow(title: "Имя пользователя", field: nameField,     action: #selector(nameChanged(_:))),
          fieldRow(title: "Телеграм",          field: tgField,       action: #selector(telegramChanged(_:))),
          fieldRow(title: "Логин",             field: emailField,    action: #selector(emailChanged(_:))),
          fieldRow(title: "Пароль",            field: passwordField, action: #selector(passwordChanged(_:)))
        ].forEach { profileStack.addArrangedSubview($0) }

        profileCard.addSubview(profileStack)
        profileStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileStack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 16),
            profileStack.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            profileStack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            profileStack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -16),
        ])

        let settingsCard = SettingsGlassCard()
        let settingsStack = UIStackView()
        settingsStack.axis = .vertical
        settingsStack.spacing = 16

        let roleTitle = UILabel()
        roleTitle.text = "Роль"
        roleTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        let roleSegment = UISegmentedControl(items: ["Студент", "Преподаватель"])
        roleSegment.selectedSegmentIndex = 0
        roleSegment.isEnabled = false
        
        self.roleSegment = roleSegment

        let roleRow = UIStackView(arrangedSubviews: [roleTitle, roleSegment])
        roleRow.axis = .vertical
        roleRow.spacing = 6

        let langTitle = UILabel()
        langTitle.text = "Язык"
        langTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        let langSegment = UISegmentedControl(items: ["Русский", "English"])
        langSegment.selectedSegmentIndex = 0
        langSegment.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
        self.langSegment = langSegment

        let langRow = UIStackView(arrangedSubviews: [langTitle, langSegment])
        langRow.axis = .vertical
        langRow.spacing = 6

        let themeTitle = UILabel()
        themeTitle.text = "Тема"
        themeTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        let themeSegment = UISegmentedControl(items: ["Система", "Светлая", "Тёмная"])
        themeSegment.selectedSegmentIndex = ThemeManager.shared.current.rawValue
        themeSegment.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
        self.themeSegment = themeSegment

        let themeRow = UIStackView(arrangedSubviews: [themeTitle, themeSegment])
        themeRow.axis = .vertical
        themeRow.spacing = 6

        let notifTitle = UILabel()
        notifTitle.text = "Уведомления"
        notifTitle.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        let notifSwitch = UISwitch()
        notifSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: .valueChanged)
        self.notifSwitch = notifSwitch

        let notifRow = UIStackView(arrangedSubviews: [notifTitle, notifSwitch])
        notifRow.axis = .horizontal
        notifRow.alignment = .center
        notifRow.spacing = 12

        [roleRow, langRow, themeRow, notifRow].forEach { settingsStack.addArrangedSubview($0) }

        settingsCard.addSubview(settingsStack)
        settingsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            settingsStack.topAnchor.constraint(equalTo: settingsCard.topAnchor, constant: 16),
            settingsStack.leadingAnchor.constraint(equalTo: settingsCard.leadingAnchor, constant: 16),
            settingsStack.trailingAnchor.constraint(equalTo: settingsCard.trailingAnchor, constant: -16),
            settingsStack.bottomAnchor.constraint(equalTo: settingsCard.bottomAnchor, constant: -16),
        ])

        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Выйти", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.layer.cornerRadius = 22
        logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        contentStack.addArrangedSubview(profileCard)
        contentStack.addArrangedSubview(settingsCard)
        contentStack.addArrangedSubview(logoutButton)
    }

    private func fillFields() {
        Task {
            if let user = await userDataTask.value {
                await MainActor.run { applyUserData(user) }
            }
        }
    }

    private func applyUserData(_ user: User) {
        nameField.text  = user.name
        tgField.text    = user.telegramId
        emailField.text = user.email

        roleSegment?.selectedSegmentIndex  = (user.role == .student ? 0 : 1)
        langSegment?.selectedSegmentIndex  = (user.language == .russian ? 0 : 1)
        themeSegment?.selectedSegmentIndex = ThemeManager.shared.current.rawValue
        notifSwitch?.isOn = user.isNotificationEnabled
    }

    // MARK: - Telegram opening

    private func setupTelegramInteractions() {
        tgField.textField.delegate = self

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleTgLongPress(_:)))
        tgField.addGestureRecognizer(lp)

        let icon = UIButton(type: .system)
        icon.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        icon.tintColor = .label
        icon.addTarget(self, action: #selector(handleTgOpenButton), for: .touchUpInside)
        icon.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        tgField.textField.rightView = icon
        tgField.textField.rightViewMode = .always
    }

    @objc private func handleTgLongPress(_ gr: UILongPressGestureRecognizer) {
        if gr.state == .began {
            allowTelegramEditing = true
            tgField.textField.becomeFirstResponder()
        }
    }

    @objc private func handleTgOpenButton() { tryOpenTelegramFromField() }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard textField === tgField.textField else { return true }
        if allowTelegramEditing {
            allowTelegramEditing = false
            return true
        }
        tryOpenTelegramFromField()
        return false
    }

    private func tryOpenTelegramFromField() {
        let raw = tgField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let username = sanitizeTelegram(raw) else {
            showAlert(title: "Telegram", message: "Укажите @username или ссылку t.me/…")
            return
        }
        openTelegram(usernameOrLink: username)
    }

    private func sanitizeTelegram(_ value: String) -> String? {
        guard !value.isEmpty else { return nil }
        var v = value

        if v.lowercased().hasPrefix("http://t.me/") || v.lowercased().hasPrefix("https://t.me/") {
            return v
        }
        if let url = URL(string: v), url.host?.lowercased() == "t.me",
           let last = url.pathComponents.last, !last.isEmpty {
            return "https://t.me/\(last)"
        }

        if v.hasPrefix("@") { v.removeFirst() }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if v.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
            return v
        }
        return nil
    }

    private func openTelegram(usernameOrLink: String) {
        if usernameOrLink.lowercased().hasPrefix("http://") || usernameOrLink.lowercased().hasPrefix("https://") {
            if let url = URL(string: usernameOrLink) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                showAlert(title: "Telegram", message: "Некорректная ссылка.")
            }
            return
        }

        let username = usernameOrLink
        let tgURL = URL(string: "tg://resolve?domain=\(username)")!
        
        if UIApplication.shared.canOpenURL(tgURL) {
            UIApplication.shared.open(tgURL, options: [:], completionHandler: nil)
        } else if let web = URL(string: "https://t.me/\(username)") {
            UIApplication.shared.open(web, options: [:], completionHandler: nil)
        } else {
            showAlert(title: "Telegram", message: "Не удалось открыть Telegram.")
        }
    }

    // MARK: - Handlers

    @objc private func themeChanged(_ sender: UISegmentedControl) {
        guard let newTheme = AppTheme(rawValue: sender.selectedSegmentIndex) else { return }
        ThemeManager.shared.current = newTheme
        setupBackground()
    }

    @objc private func themeDidChange() {
        themeSegment?.selectedSegmentIndex = ThemeManager.shared.current.rawValue
        setupBackground()
    }

    @objc private func logoutTapped() {
        Task { [weak self] in
            let deviceId = DeviceIdProvider.shared.deviceId
            if let uid = Auth.auth().currentUser?.uid {
                await DependencyInjection.shared.sessionService.endSession(uid: uid, deviceId: deviceId)
            }
            do { try Auth.auth().signOut() } catch { return }
            DependencyInjection.shared.currentUser.clear()
            await MainActor.run {
                let vc = LoginViewController()
                vc.modalPresentationStyle = .fullScreen
                self?.present(vc, animated: true)
            }
        }
    }

    @objc private func nameChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty,
              let uid = Auth.auth().currentUser?.uid else { return }
        updateUser(with: UserUpdate(id: uid, name: text))
    }

    @objc private func telegramChanged(_ sender: UITextField) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        updateUser(with: UserUpdate(id: uid, telegramId: text))
    }

    @objc private func emailChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        updateEmail(text)
    }

    @objc private func passwordChanged(_ sender: UITextField) {
        guard let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        updatePassword(text)
    }

    @objc private func roleChanged(_ sender: UISegmentedControl) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newRole: Role = sender.selectedSegmentIndex == 0 ? .student : .teacher
        updateUser(with: UserUpdate(id: uid, role: newRole))
    }

    @objc private func languageChanged(_ sender: UISegmentedControl) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newLanguage: Language = sender.selectedSegmentIndex == 0 ? .russian : .english
        updateUser(with: UserUpdate(id: uid, language: newLanguage))
    }

    @objc private func notificationChanged(_ sender: UISwitch) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        updateUser(with: UserUpdate(id: uid, isNotificationEnabled: sender.isOn))
    }
    
    @objc private func avatarTapped() {
        let actionSheet = UIAlertController(title: "Выберите иконку", message: nil, preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Снять фото", style: .default) { [weak self] _ in
            self?.openCamera()
        }
        
        let chooseFromGalleryAction = UIAlertAction(title: "Выбрать из галереи", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        actionSheet.addAction(takePhotoAction)
        actionSheet.addAction(chooseFromGalleryAction)
        actionSheet.addAction(cancelAction)
        
        // Для iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = avatarImageView
            popover.sourceRect = avatarImageView.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Ошибка", message: "Камера недоступна")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func updateUser(with update: UserUpdate) {
        Task {
            do { try await userService.updateUser(update) }
            catch { await MainActor.run { showAlert(title: "Ошибка", message: "Не удалось сохранить изменения") } }
        }
    }

    private func updateEmail(_ newEmail: String) {
        Task {
            do {
                try await userService.updateEmail(newEmail)
                await MainActor.run { showAlert(title: "Успешно", message: "Email обновлён") }
            } catch {
                await MainActor.run { showAlert(title: "Ошибка", message: "Не удалось обновить email: \(error.localizedDescription)") }
            }
        }
    }

    private func updatePassword(_ newPassword: String) {
        Task {
            do {
                try await userService.updatePassword(newPassword)
                await MainActor.run { showAlert(title: "Успешно", message: "Пароль обновлён") }
            } catch {
                await MainActor.run { showAlert(title: "Ошибка", message: "Не удалось обновить пароль: \(error.localizedDescription)") }
            }
        }
    }
    
    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
    
    private func loadOrCreateProfilePhoto() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let docRef = db.collection(profilePhotosCollection).document(userId)

        docRef.getDocument { [weak self] snapshot, _ in
            if let data = snapshot?.data(),
               let base64 = data["photoBase64"] as? String,
               !base64.isEmpty,
               let image = self?.decodeBase64ToImage(base64) {
                self?.avatarImageView.image = image
                return
            }

            // нет фото — показываем дефолт и гарантированно создаём документ
            if let defaultImage = UIImage(named: "avatar") {
                self?.avatarImageView.image = defaultImage
            }
            docRef.setData([
                "id": userId,
                "photoBase64": ""
            ], merge: true)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        
        // Устанавливаем изображение сразу в UIImageView
        avatarImageView.image = image
        
        // Сохраняем в Firebase (но НЕ загружаем снова)
        saveAvatarToFirestoreBase64(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func saveAvatarToFirestoreBase64(_ image: UIImage) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let base64 = encodeImageToBase64(image) else {
            showAlert(title: "Ошибка", message: "Слишком большой файл: не удалось сжать до 1 МБ")
            return
        }
        let db = Firestore.firestore()
        db.collection(profilePhotosCollection).document(userId).setData([
            "id": userId,
            "photoBase64": base64
        ], merge: true) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Ошибка", message: "Не удалось сохранить фото профиля: \(error.localizedDescription)")
            } else {
                print("Аватар сохранён в Firestore как base64")
            }
        }
    }
    
    private func encodeImageToBase64(_ image: UIImage, maxBytes: Int = 900 * 1024) -> String? {
        var quality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: quality)
        while let d = data, d.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        guard let finalData = data, finalData.count <= maxBytes else { return nil }
        return finalData.base64EncodedString()
    }

    private func decodeBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
