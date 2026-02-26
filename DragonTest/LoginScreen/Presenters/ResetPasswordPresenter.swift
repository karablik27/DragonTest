//
//  ResetPasswordPresenter.swift
//  DragonTest
//
//  Created by Sergey on 26.02.2026.
//

import UIKit

final class ResetPasswordPresenter: ResetPasswordViewOutput {
    weak var view: ResetPasswordViewInput?
    private let authService: AuthenticationServiceProtocol

    init(view: ResetPasswordViewInput, authService: AuthenticationServiceProtocol) {
        self.view = view
        self.authService = authService
    }

    func viewDidLoad() {}

    func didTapSend(email: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(email) else {
            view?.showError("Введите корректную почту")
            return
        }

        view?.closeKeyboard()
        view?.setLoading(true)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.authService.resetPassword(email: email)
                await MainActor.run {
                    self.view?.setLoading(false)
                    self.view?.showSuccessAndClose("Письмо для сброса пароля отправлено на почту")
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

    private func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return email.contains("@") && email.contains(".") && !email.contains(" ")
    }

    private func map(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case 17008: return "Неверный формат email."
        case 17011: return "Пользователь с таким e-mail не найден."
        case 17020: return "Ошибка сети (нет интернета)."
        default: return ns.localizedDescription
        }
    }
}
