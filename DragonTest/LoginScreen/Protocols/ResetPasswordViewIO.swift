//
//  ResetPasswordViewIO.swift
//  DragonTest
//
//  Created by Sergey on 26.02.2026.
//

protocol ResetPasswordViewInput: AnyObject {
    func setLoading(_ isLoading: Bool)
    func showError(_ message: String)
    func showSuccessAndClose(_ message: String)
    func closeKeyboard()
    func backToLogin()
}

protocol ResetPasswordViewOutput: AnyObject {
    func viewDidLoad()
    func didTapSend(email: String)
    func didTapBack()
}
