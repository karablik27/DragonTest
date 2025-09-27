//
//  SettingsViewController.swift
//  DragonTest
//
//  Created by Лазарева Александра on 18.09.2025.
//

import Photos
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

final class SettingsViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SettingsViewProtocol {

    // MARK: - MVP
    private var presenter: SettingsPresenterProtocol!

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var headerView: UIView!

    private let avatarImageView = UIImageView()

    private weak var themeSegment: UISegmentedControl?
    private weak var roleSegment: UISegmentedControl?
    private weak var langSegment: UISegmentedControl?
    private weak var notifSwitch: UISwitch?

    private let nameField = SettingsGlassTextField(placeholder: "Введите имя")
    private let tgField = SettingsGlassTextField(placeholder: "@username")
    private let emailField = SettingsGlassTextField(placeholder: "example@mail.com", isSecure: false, keyboard: .emailAddress)
    private let passwordField = SettingsGlassTextField(placeholder: "Введите новый пароль", isSecure: true, keyboard: .default)

    private var allowTelegramEditing = false

    // MARK: - Init
    override init(nibName: String? = nil, bundle: Bundle? = nil) {
        super.init(nibName: nibName, bundle: bundle)
        // Внедряем презентер
        let userService: UserServiceProtocol = UserService(dataBase: Firestore.firestore())
        self.presenter = SettingsPresenter(userService: userService)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let userService: UserServiceProtocol = UserService(dataBase: Firestore.firestore())
        self.presenter = SettingsPresenter(userService: userService)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupLayout()
        buildForm()
        setupTelegramInteractions()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .appThemeDidChange, object: nil)

        presenter.attach(view: self)
        presenter.viewDidLoad()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

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

    // MARK: - Background
    func applyBackground() { setupBackground() }

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
        gradient.locations = [0.0, 0.25, 0.65, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        gradient.zPosition = -1000
        view.layer.insertSublayer(gradient, at: 0)
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
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),

            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    private func buildHeader() -> UIView {
        let container = UIView()

        let usernameLabel = UILabel()
        usernameLabel.text = "Настройки"
        usernameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        usernameLabel.textColor = .label

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

        let hStack = UIStackView(arrangedSubviews: [usernameLabel, UIView(), rightStack])
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

    // MARK: - Form
    private func buildForm() {
        // Профиль
        let profileCard = SettingsGlassCard()
        let profileStack = UIStackView()
        profileStack.axis = .vertical
        profileStack.spacing = 10

        func fieldRow(title: String, field: SettingsGlassTextField, action: Selector?) -> UIView {
            let t = UILabel()
            t.text = title
            t.font = .systemFont(ofSize: 14, weight: .medium)
            t.textColor = .label
            if let action { field.textField.addTarget(self, action: action, for: .editingDidEnd) }
            let v = UIStackView(arrangedSubviews: [t, field])
            v.axis = .vertical
            v.spacing = 6
            return v
        }

        [
            fieldRow(title: "Имя пользователя", field: nameField,     action: #selector(nameChanged(_:))),
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

        // Настройки
        let settingsCard = SettingsGlassCard()
        let settingsStack = UIStackView()
        settingsStack.axis = .vertical
        settingsStack.spacing = 16

        let roleTitle = UILabel()
        roleTitle.text = "Роль"
        roleTitle.font = .systemFont(ofSize: 14, weight: .medium)

        let roleSegment = UISegmentedControl(items: ["Студент", "Преподаватель"])
        roleSegment.selectedSegmentIndex = 0
        roleSegment.isEnabled = false // как и было
        roleSegment.addTarget(self, action: #selector(roleChanged(_:)), for: .valueChanged)
        self.roleSegment = roleSegment

        let roleRow = UIStackView(arrangedSubviews: [roleTitle, roleSegment])
        roleRow.axis = .vertical
        roleRow.spacing = 6

        let themeTitle = UILabel()
        themeTitle.text = "Тема"
        themeTitle.font = .systemFont(ofSize: 14, weight: .medium)

        let themeSegment = UISegmentedControl(items: ["Система", "Светлая", "Тёмная"])
        themeSegment.selectedSegmentIndex = ThemeManager.shared.current.rawValue
        themeSegment.addTarget(self, action: #selector(themeChanged(_:)), for: .valueChanged)
        self.themeSegment = themeSegment

        let themeRow = UIStackView(arrangedSubviews: [themeTitle, themeSegment])
        themeRow.axis = .vertical
        themeRow.spacing = 6

        let notifTitle = UILabel()
        notifTitle.text = "Уведомления"
        notifTitle.font = .systemFont(ofSize: 14, weight: .medium)

        let notifSwitch = UISwitch()
        notifSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: .valueChanged)
        self.notifSwitch = notifSwitch

        let notifRow = UIStackView(arrangedSubviews: [notifTitle, notifSwitch])
        notifRow.axis = .horizontal
        notifRow.alignment = .center
        notifRow.spacing = 12

        [roleRow, themeRow, notifRow].forEach { settingsStack.addArrangedSubview($0) }

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

    func reloadLayoutIfNeeded() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - Telegram open UX
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

        if v.lowercased().hasPrefix("http://t.me/") || v.lowercased().hasPrefix("https://t.me/") { return v }
        if let url = URL(string: v), url.host?.lowercased() == "t.me",
           let last = url.pathComponents.last, !last.isEmpty { return "https://t.me/\(last)" }

        if v.hasPrefix("@") { v.removeFirst() }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if v.unicodeScalars.allSatisfy({ allowed.contains($0) }) { return v }
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

    // MARK: - Handlers (пробрасываем в презентер)
    @objc private func themeChanged(_ sender: UISegmentedControl) {
        presenter.themeChanged(index: sender.selectedSegmentIndex)
    }

    @objc private func themeDidChange() {
        themeSegment?.selectedSegmentIndex = ThemeManager.shared.current.rawValue
        applyBackground()
    }

    @objc private func logoutTapped() { presenter.logoutTapped() }

    @objc private func nameChanged(_ sender: UITextField) {
        presenter.nameChanged(sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    @objc private func telegramChanged(_ sender: UITextField) {
        presenter.telegramChanged(sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    @objc private func emailChanged(_ sender: UITextField) {
        presenter.emailChanged(sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    @objc private func passwordChanged(_ sender: UITextField) {
        presenter.passwordChanged(sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
    }

    @objc private func roleChanged(_ sender: UISegmentedControl) {
        presenter.roleChanged(index: sender.selectedSegmentIndex)
    }

    @objc private func notificationChanged(_ sender: UISwitch) {
        presenter.notificationsChanged(sender.isOn)
    }

    // MARK: - Avatar picking
    @objc private func avatarTapped() {
        let actionSheet = UIAlertController(title: "Выберите иконку", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Снять фото", style: .default) { [weak self] _ in self?.openCamera() })
        actionSheet.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default) { [weak self] _ in self?.openPhotoLibrary() })
        actionSheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = avatarImageView
            popover.sourceRect = avatarImageView.bounds
        }
        present(actionSheet, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Ошибка", message: "Камера недоступна"); return
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

    // UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        presenter.didPickAvatar(image)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }

    // MARK: - SettingsViewProtocol impl

    func setFields(name: String?, tg: String?, email: String?) {
        nameField.text  = name
        tgField.text    = tg
        emailField.text = email
    }

    func setRoleIndex(_ index: Int) { roleSegment?.selectedSegmentIndex = index }
    func setThemeIndex(_ index: Int) { themeSegment?.selectedSegmentIndex = index }
    func setNotifications(_ isOn: Bool) { notifSwitch?.isOn = isOn }

    func setAvatar(_ image: UIImage) { avatarImageView.image = image }
    func setAvatarPlaceholder() {
        if let img = UIImage(named: "avatar") { avatarImageView.image = img }
        else { avatarImageView.image = UIImage(systemName: "person.crop.circle") }
    }

    func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    func openLoginScreen() {
        let vc = LoginViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
