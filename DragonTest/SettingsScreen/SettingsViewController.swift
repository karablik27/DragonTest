//
//  SettingsViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

// TODO: Переделать под дизайн
import Photos
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

final class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let userService: UserServiceProtocol = UserService(dataBase: Firestore.firestore())
    private let avatarImageView = UIImageView()
    private let profilePhotosCollection = "profilePhoto"
    
    private var userDataTask: Task<User?, Never> = Task { nil }

    override init(nibName: String? = nil, bundle: Bundle? = nil) {
        super.init(nibName: nibName, bundle: bundle)
        userDataTask = loadUserData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        userDataTask = loadUserData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Настройки"
        
        setupBackground()
        setupLayout()
        addProfileSettings()
        fillFields()
        loadOrCreateProfilePhoto()
    }
    
    // MARK: - Data Loading
    private func loadUserData() -> Task<User?, Never> {
        guard let uid = Auth.auth().currentUser?.uid else { 
            return Task { nil }
        }
        
        return Task { [weak self] in
            do {
                return try await self?.userService.fetchUser(uid: uid)
            } catch {
                await MainActor.run {
                    self?.showAlert(title: "Ошибка", message: "Не удалось загрузить данные профиля")
                }
                return nil
            }
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
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
        
        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatarImageView.addGestureRecognizer(tapGesture)
        view.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            avatarImageView.widthAnchor.constraint(equalToConstant: 120),
            avatarImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
        scrollView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 20).isActive = true
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
        
        func makeField(title: String, placeholder: String, isSecure: Bool = false, action: Selector) -> UIStackView {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            
            let textField = UITextField()
            textField.placeholder = placeholder
            textField.borderStyle = .roundedRect
            textField.isSecureTextEntry = isSecure
            textField.addTarget(self, action: action, for: .editingDidEnd)
            
            let stack = UIStackView(arrangedSubviews: [label, textField])
            stack.axis = .vertical
            stack.spacing = 6
            return stack
        }
    
        let nameField = makeField(title: "Имя пользователя", placeholder: "Введите имя", action: #selector(nameChanged(_:)))
        let tgField = makeField(title: "Телеграмм", placeholder: "Введите телеграмм", action: #selector(telegramChanged(_:)))
        let loginField = makeField(title: "Логин", placeholder: "example@mail.com", action: #selector(emailChanged(_:)))
        let passwordField = makeField(title: "Пароль", placeholder: "Введите новый пароль", isSecure: true, action: #selector(passwordChanged(_:)))
        
        let roleLabel = UILabel()
        roleLabel.text = "Роль"
        roleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let roleSegment = UISegmentedControl(items: ["Студент", "Преподаватель"])
        roleSegment.selectedSegmentIndex = 0
        roleSegment.addTarget(self, action: #selector(roleChanged(_:)), for: .valueChanged)
        let roleStack = UIStackView(arrangedSubviews: [roleLabel, roleSegment])
        roleStack.axis = .vertical
        roleStack.spacing = 6
        
        let langLabel = UILabel()
        langLabel.text = "Язык"
        langLabel.font = .systemFont(ofSize: 14, weight: .medium)
        let langSegment = UISegmentedControl(items: ["Русский", "English"])
        langSegment.selectedSegmentIndex = 0
        langSegment.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
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
        notifSwitch.addTarget(self, action: #selector(notificationChanged(_:)), for: .valueChanged)
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

        nameField.tag = 1
        tgField.tag = 2
        loginField.tag = 3
        roleStack.tag = 4
        langStack.tag = 5
        notifStack.tag = 6
        
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
    

    
    private func fillFields() {
        Task {
            if let user = await userDataTask.value {
                await MainActor.run {
                    applyUserData(user)
                }
            }
        }
    }
    
    private func applyUserData(_ user: User) {
        if let nameStack = contentStack.arrangedSubviews.first(where: { $0.tag == 1 }) as? UIStackView,
           let nameField = nameStack.arrangedSubviews.last as? UITextField {
            nameField.text = user.name
        }
        
        if let tgStack = contentStack.arrangedSubviews.first(where: { $0.tag == 2 }) as? UIStackView,
           let tgField = tgStack.arrangedSubviews.last as? UITextField {
            tgField.text = user.telegramId
        }
        
        if let loginStack = contentStack.arrangedSubviews.first(where: { $0.tag == 3 }) as? UIStackView,
           let loginField = loginStack.arrangedSubviews.last as? UITextField {
            loginField.text = user.email
        }
        
        if let roleStack = contentStack.arrangedSubviews.first(where: { $0.tag == 4 }) as? UIStackView,
           let roleSegment = roleStack.arrangedSubviews.first(where: { $0 is UISegmentedControl }) as? UISegmentedControl {
            roleSegment.selectedSegmentIndex = user.role == .student ? 0 : 1
        }
        
        if let langStack = contentStack.arrangedSubviews.first(where: { $0.tag == 5 }) as? UIStackView,
           let langSegment = langStack.arrangedSubviews.first(where: { $0 is UISegmentedControl }) as? UISegmentedControl {
            langSegment.selectedSegmentIndex = user.language == .russian ? 0 : 1
        }
        
        if let notifStack = contentStack.arrangedSubviews.first(where: { $0.tag == 6 }) as? UIStackView,
           let notifSwitch = notifStack.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch {
            notifSwitch.isOn = user.isNotificationEnabled
        }
    }
    
    @objc private func logoutTapped() {
        Task { [weak self] in
            let deviceId = DeviceIdProvider.shared.deviceId
            if let uid = Auth.auth().currentUser?.uid {
                await DependencyInjection.shared.sessionService.endSession(
                    uid: uid,
                    deviceId: deviceId
                )
            }

            do {
                try Auth.auth().signOut()
            } catch {
                return
            }

            DependencyInjection.shared.currentUser.clear()

            await MainActor.run {
                // верни пользователя на экран логина
                let vc = LoginViewController()
                vc.modalPresentationStyle = .fullScreen
                self?.present(vc, animated: true)
            }
        }
    }
    
    // MARK: - Edition handlers
    
    @objc private func nameChanged(_ sender: UITextField) {
        guard let text = sender.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let uid = Auth.auth().currentUser?.uid else { return }
        
        let update = UserUpdate(id: uid, name: text.trimmingCharacters(in: .whitespacesAndNewlines))
        updateUser(with: update)
    }
    
    @objc private func telegramChanged(_ sender: UITextField) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let text = sender.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let update = UserUpdate(id: uid, telegramId: text)
        updateUser(with: update)
    }
    
    @objc private func emailChanged(_ sender: UITextField) {
        guard let text = sender.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newEmail = text.trimmingCharacters(in: .whitespacesAndNewlines)
        updateEmail(newEmail)
    }
    
    @objc private func passwordChanged(_ sender: UITextField) {
        guard let text = sender.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newPassword = text.trimmingCharacters(in: .whitespacesAndNewlines)
        updatePassword(newPassword)
    }
    
    @objc private func roleChanged(_ sender: UISegmentedControl) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newRole: Role = sender.selectedSegmentIndex == 0 ? .student : .teacher
        
        let update = UserUpdate(id: uid, role: newRole)
        updateUser(with: update)
    }
    
    @objc private func languageChanged(_ sender: UISegmentedControl) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let newLanguage: Language = sender.selectedSegmentIndex == 0 ? .russian : .english
        
        let update = UserUpdate(id: uid, language: newLanguage)
        updateUser(with: update)
    }
    
    @objc private func notificationChanged(_ sender: UISwitch) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let update = UserUpdate(id: uid, isNotificationEnabled: sender.isOn)
        updateUser(with: update)
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
            do {
                try await userService.updateUser(update)
            } catch {
                await MainActor.run {
                    showAlert(title: "Ошибка", message: "Не удалось сохранить изменения")
                }
            }
        }
    }
    
    private func updateEmail(_ newEmail: String) {
        Task {
            do {
                try await userService.updateEmail(newEmail)
                await MainActor.run {
                    showAlert(title: "Успешно", message: "Email обновлен")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Ошибка", message: "Не удалось обновить email: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updatePassword(_ newPassword: String) {
        Task {
            do {
                try await userService.updatePassword(newPassword)
                await MainActor.run {
                    showAlert(title: "Успешно", message: "Пароль обновлен")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Ошибка", message: "Не удалось обновить пароль: \(error.localizedDescription)")
                }
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
