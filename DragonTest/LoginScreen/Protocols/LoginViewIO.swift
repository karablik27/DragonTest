//
//  LoginViewIO.swift
//  DragonTest
//
//  Created by Крючков Сергей on 23.09.2025.
//

protocol LoginViewInput: AnyObject {
    func setLoading(_ isLoading: Bool)
    func showError(_ message: String)
    func closeKeyboard()
    func openMain()
    func openSignUp()
}

protocol LoginViewOutput: AnyObject {
    func viewDidLoad()
    func didTapLogin(email: String, password: String)
    func didTapSignUp()
    func didTapForgotPassword(email: String)
}
