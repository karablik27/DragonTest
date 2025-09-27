//
//  SignUpPresenter.swift
//  DragonTest
//
//  Created by Sergey on 23.09.2025.
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
                      role: Role, language: Language) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !email.isEmpty, !password.isEmpty else {
            view?.showError("signup.fill_email_password".localized)
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
                user.role = role
                user.language = language

                try await self.userService.saveUser(user)
                
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
                        self.view?.showError("signup.account_active_another_device".localized)
                    }
                    return
                }
                
                DependencyInjection.shared.currentUser.userId = user.id
                DependencyInjection.shared.currentUser.role = .student
                
                await MainActor.run {
                    self.view?.setLoading(false)
                    self.view?.showSuccess()
                    self.view?.openMain()
                }
                DependencyInjection.shared.currentUser.userId = user.id
                DependencyInjection.shared.currentUser.role = .student
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
        case 17007: return "signup.email_already_used".localized
        case 17008: return "signup.invalid_email_format".localized
        case 17026: return "signup.weak_password".localized
        case 17020: return "signup.network_error".localized
        default: return ns.localizedDescription
        }
    }
}
