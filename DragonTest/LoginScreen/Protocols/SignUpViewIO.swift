//
//  SignUpViewIO.swift
//  DragonTest
//
//  Created by Sergey on 23.09.2025.
//

protocol SignUpViewInput: AnyObject {
    func setLoading(_ isLoading: Bool)
    func showError(_ message: String)
    func showSuccess()
    func openMain()
    func backToLogin()
}

protocol SignUpViewOutput: AnyObject {
    func viewDidLoad()
    func didTapSignUp(name: String, surname: String, lastname: String,
                      email: String, password: String, telegramId: String,
                      role: Role)
    func didTapBack()
}
