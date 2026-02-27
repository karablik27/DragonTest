//
//  SettingsPresenter.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class SettingsPresenter: SettingsPresenterProtocol {

    private weak var view: SettingsViewProtocol?

    // DI
    private let userService: UserServiceProtocol
    private let auth: Auth
    private let db: Firestore
    private let profilePhotosCollection: String

    // State
    private var currentUser: User?

    init(userService: UserServiceProtocol,
         auth: Auth = Auth.auth(),
         db: Firestore = Firestore.firestore(),
         profilePhotosCollection: String = "profilePhoto") {
        self.userService = userService
        self.auth = auth
        self.db = db
        self.profilePhotosCollection = profilePhotosCollection
    }

    func attach(view: SettingsViewProtocol) { self.view = view }

    func viewDidLoad() {
        view?.applyBackground()
        view?.setLoading(true)
        Task { await loadUserAndAvatar() }
    }

    // MARK: - Inputs

    func themeChanged(index: Int) {
        guard let newTheme = AppTheme(rawValue: index) else { return }
        ThemeManager.shared.current = newTheme
        view?.setThemeIndex(index)
        view?.applyBackground()
    }

    func logoutTapped() {
        Task { [weak self] in
            guard let self else { return }
            let deviceId = DeviceIdProvider.shared.deviceId
            if let uid = auth.currentUser?.uid {
                await DependencyInjection.shared.sessionService.endSession(uid: uid, deviceId: deviceId)
            }
            do {
                try auth.signOut()
            } catch {
                await MainActor.run {
                    self.view?.showAlert(title: "Ошибка", message: "Не удалось выйти из аккаунта")
                }
                return
            }
            DependencyInjection.shared.currentUser.clear()
            await MainActor.run { self.view?.openLoginScreen() }
        }
    }

    func nameChanged(_ text: String) {
        guard let uid = auth.currentUser?.uid, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        updateUser(UserUpdate(id: uid, name: text))
    }

    func telegramChanged(_ text: String) {
        guard let uid = auth.currentUser?.uid else { return }
        updateUser(UserUpdate(id: uid, telegramId: text.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    func emailChanged(_ text: String) {
        let email = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else { return }
        Task {
            do {
                try await userService.updateEmail(email)
                await MainActor.run {
                    self.view?.showAlert(title: "Успешно", message: "Email обновлён")
                }
            } catch {
                await MainActor.run {
                    self.view?.showAlert(title: "Ошибка", message: "Не удалось обновить email: \(error.localizedDescription)")
                }
            }
        }
    }

    func passwordChanged(_ text: String) {
        let pwd = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pwd.isEmpty else { return }
        Task {
            do {
                try await userService.updatePassword(pwd)
                await MainActor.run {
                    self.view?.showAlert(title: "Успешно", message: "Пароль обновлён")
                }
            } catch {
                await MainActor.run {
                    self.view?.showAlert(title: "Ошибка", message: "Не удалось обновить пароль: \(error.localizedDescription)")
                }
            }
        }
    }

    func roleChanged(index: Int) {
        guard let uid = auth.currentUser?.uid else { return }
        let newRole: Role = (index == 0) ? .student : .teacher
        updateUser(UserUpdate(id: uid, role: newRole))
    }

    func notificationsChanged(_ isOn: Bool) {
        guard let uid = auth.currentUser?.uid else { return }
        updateUser(UserUpdate(id: uid, isNotificationEnabled: isOn))
    }

    // MARK: - Avatar

    func didPickAvatar(_ image: UIImage) {
        guard let uid = auth.currentUser?.uid else { return }
        guard let base64 = encodeImageToBase64(image) else {
            view?.showAlert(title: "Ошибка", message: "Слишком большой файл: не удалось сжать до 1 МБ")
            return
        }
        db.collection(profilePhotosCollection).document(uid).setData([
            "id": uid,
            "photoBase64": base64
        ], merge: true) { [weak self] error in
            if let error = error {
                self?.view?.showAlert(title: "Ошибка", message: "Не удалось сохранить фото профиля: \(error.localizedDescription)")
            } else {
                self?.view?.setAvatar(image)
            }
        }
    }

    // MARK: - Private

    private func updateUser(_ update: UserUpdate) {
        Task {
            do {
                try await userService.updateUser(update)
            } catch {
                await MainActor.run {
                    self.view?.showAlert(title: "Ошибка", message: "Не удалось сохранить изменения")
                }
            }
        }
    }

    private func loadUserAndAvatar() async {
        guard let uid = auth.currentUser?.uid else {
            await MainActor.run { self.view?.setLoading(false) }
            return
        }

        // user
        do {
            let user = try await userService.fetchUser(uid: uid)
            currentUser = user
            await MainActor.run {
                self.view?.setFields(name: user.name, tg: user.telegramId, email: user.email)
                self.view?.setRoleIndex(user.role == .student ? 0 : 1)
                self.view?.setThemeIndex(ThemeManager.shared.current.rawValue)
                self.view?.setNotifications(user.isNotificationEnabled)
                self.view?.reloadLayoutIfNeeded()
                self.view?.setLoading(false)
            }
        } catch {
            await MainActor.run {
                self.view?.setLoading(false)
                self.view?.showAlert(title: "Ошибка", message: "Не удалось загрузить профиль")
            }
        }

        // avatar
        await loadOrCreateProfilePhoto(uid: uid)
    }

    private func loadOrCreateProfilePhoto(uid: String) async {
        let docRef = db.collection(profilePhotosCollection).document(uid)
        do {
            let snap = try await docRef.getDocument()
            if let data = snap.data(),
               let base64 = data["photoBase64"] as? String,
               !base64.isEmpty,
               let img = decodeBase64ToImage(base64) {
                await MainActor.run { self.view?.setAvatar(img) }
                return
            }
            // ensure doc exists, show placeholder
            try await docRef.setData(["id": uid, "photoBase64": ""], merge: true)
            await MainActor.run { self.view?.setAvatarPlaceholder() }
        } catch {
            await MainActor.run { self.view?.setAvatarPlaceholder() }
        }
    }

    private func encodeImageToBase64(_ image: UIImage, maxBytes: Int = 900 * 1024) -> String? {
        var quality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: quality)
        while let d = data, d.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }
        guard let final = data, final.count <= maxBytes else { return nil }
        return final.base64EncodedString()
    }

    private func decodeBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}
