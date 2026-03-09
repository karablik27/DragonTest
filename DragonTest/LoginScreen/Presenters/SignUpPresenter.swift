//
//  SignUpPresenter.swift
//  DragonTest
//
//  Created by Крючков Сергей on 23.09.2025.
//

import UIKit

final class SignUpPresenter: SignUpViewOutput {
    weak var view: SignUpViewInput?
    
    private let authService: AuthenticationServiceProtocol
    private let userService: UserServiceProtocol
    private let sessionService: SessionServiceProtocol
    
    init(view: SignUpViewInput,
         authService: AuthenticationServiceProtocol,
         userService: UserServiceProtocol,
         sessionService: SessionServiceProtocol = DependencyInjection.shared.sessionService) {
        self.view = view
        self.authService = authService
        self.userService = userService
        self.sessionService = sessionService
    }
    
    func viewDidLoad() {}
    
    func didTapSignUp(name: String, surname: String, lastname: String,
                      email: String, password: String, telegramId: String,
                      role: Role) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let emailLowercased = email.lowercased()

        let specialEmails: Set<String> = [
            Secrets.devTeacherEmail1.lowercased(),
            Secrets.devTeacherEmail2.lowercased()
        ]

        let resolvedRole: Role = specialEmails.contains(emailLowercased) ? .teacher : .student
        
        guard !email.isEmpty, !password.isEmpty else {
            view?.showError("Заполните почту и пароль")
            return
        }
        view?.setLoading(true)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                var user = try await self.authService.createUser(email: email, password: password)
                user.name = name
                user.surname = surname
                user.lastname = lastname
                user.telegramId = telegramId
                user.role = resolvedRole
                
                try await self.userService.saveUser(user)
                
                if specialEmails.contains(emailLowercased) {
                    let deviceId = DeviceIdProvider.shared.deviceId
                    do {
                        _ = try await self.sessionService.startSession(
                            uid: user.id,
                            deviceId: deviceId,
                            force: false
                        )
                    } catch {
                        await MainActor.run {
                            self.view?.setLoading(false)
                            self.view?.showError("Аккаунт уже активен на другом устройстве. Пожалуйста, завершите сессию на другом устройстве.")
                        }
                        return
                    }

                    DependencyInjection.shared.currentUser.userId = user.id
                    DependencyInjection.shared.currentUser.role = user.role

                    await MainActor.run {
                        self.view?.setLoading(false)
                        self.view?.openMain()
                    }
                } else {
                    await MainActor.run {
                        self.view?.setLoading(false)
                        self.view?.openEmailVerification(user: user)
                    }
                }
            } catch {
                await MainActor.run {
                    self.view?.setLoading(false)
                    self.view?.showError(self.map(error))
                }
            }
        }
    }
    
    func didTapBack() {
        view?.backToLogin()
    }
    
    private func map(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case 17007: return "Email уже используется."
        case 17008: return "Неверный формат email."
        case 17026: return "Слабый пароль (минимум 6 символов)."
        case 17020: return "Ошибка сети. Проверьте интернет."
        default: return ns.localizedDescription
        }
    }
}
