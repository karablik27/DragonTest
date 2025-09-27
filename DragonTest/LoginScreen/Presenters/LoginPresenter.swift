//
//  LoginPresenter.swift
//  DragonTest
//
//  Created by Sergey on 23.09.2025.
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
            view?.showError("login.error.empty_fields".localized)
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
                        self.view?.showError("login.error.session_active".localized)
                    }
                    return
                }
                
                let fullUser = try await DependencyInjection.shared.userService.fetchUser(uid: firebaseUser.id)
                
                DependencyInjection.shared.localizationService.changeLanguage(to: fullUser.language)
                
                DependencyInjection.shared.currentUser.userId = fullUser.id
                DependencyInjection.shared.currentUser.role = fullUser.role
                
                await MainActor.run {
                    self.view?.setLoading(false)
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
        case 17004: return "login.error.wrong_password".localized
        case 17007: return "login.error.email_already_registered".localized
        case 17008: return "login.error.invalid_email_format".localized
        case 17009: return "login.error.invalid_credentials".localized
        case 17011: return "login.error.user_not_found".localized
        case 17020: return "login.error.network_no_internet".localized
        default: return ns.localizedDescription
        }
    }
}
