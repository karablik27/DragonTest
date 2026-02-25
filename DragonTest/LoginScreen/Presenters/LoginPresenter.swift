//
//  LoginPresenter.swift
//  DragonTest
//
//  Created by Крючков Сергей on 23.09.2025.
//

import UIKit

final class LoginPresenter: LoginViewOutput {
    
    weak var view: LoginViewInput?
    private let authService: AuthenticationServiceProtocol
    
    init(view: LoginViewInput, authService: AuthenticationServiceProtocol) {
        self.view = view
        self.authService = authService
    }
    
    func viewDidLoad() { }
    
    func didTapLogin(email: String, password: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            view?.showError("Введите почту и пароль")
            return
        }
        view?.closeKeyboard()
        view?.setLoading(true)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let firebaseUser = try await self.authService.signInUser(email: email, password: password)

                let deviceId = DeviceIdProvider.shared.deviceId
                do {
                    _ = try await DependencyInjection.shared.sessionService.startSession(
                        uid: firebaseUser.id,
                        deviceId: deviceId,
                        force: false
                    )
                } catch {
                    await MainActor.run {
                        self.view?.setLoading(false)
                        self.view?.showError("Аккаунт используется на другом устройстве. Пожалуйста, выйдите из прошлой сессии.")
                    }
                    return
                }
                
                let fullUser = try await DependencyInjection.shared.userService.fetchUser(uid: firebaseUser.id)
                
                DependencyInjection.shared.currentUser.userId = fullUser.id
                DependencyInjection.shared.currentUser.role = fullUser.role
                
                await MainActor.run {
                    self.view?.openMain()
                }
            } catch {
                await MainActor.run {
                    self.view?.setLoading(false)
                    self.view?.showError(self.map(error))
                }
            }
        }
    }
    
    func didTapSignUp() {
        view?.openSignUp()
    }
    
    private func map(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case 17004: return "Неверный пароль."
        case 17007: return "Пользователь с таким e-mail уже зарегистрирован."
        case 17008: return "Неверный формат email."
        case 17009: return "Некорректные учетные данные."
        case 17011: return "Пользователь с такие e-mail не найден."
        case 17020: return "Ошибка сети (нет интернета)."
        default: return ns.localizedDescription
        }
    }
}
