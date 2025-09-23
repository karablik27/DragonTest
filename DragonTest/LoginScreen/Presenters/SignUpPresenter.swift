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
    
    init(view: SignUpViewInput,
         authService: AuthenticationServiceProtocol,
         userService: UserServiceProtocol) {
        self.view = view
        self.authService = authService
        self.userService = userService
    }
    
    func viewDidLoad() {}
    
    func didTapSignUp(name: String, surname: String, lastname: String,
                      email: String, password: String, telegramId: String,
                      role: Role, language: Language) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
                user.role = role
                user.language = language

                try await self.userService.saveUser(user)

                await MainActor.run {
                    self.view?.setLoading(false)
                    self.view?.showSuccess()
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
