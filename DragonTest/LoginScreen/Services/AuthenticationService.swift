//
//  AuthenticationService.swift
//  DragonTest
//
//  Created by Крючков Сергей on 20.09.2025.
//

import UIKit
import FirebaseAuth


final class AuthenticationService: AuthenticationServiceProtocol {
    func createUser(email: String, password: String) async throws -> User {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)

        try await authDataResult.user.sendEmailVerification()

        return User(firebaseUser: authDataResult.user)
    }
    
    func signInUser(email: String, password: String) async throws -> User {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let firebaseUser = authDataResult.user

        try await firebaseUser.reload()
        guard firebaseUser.isEmailVerified || Secrets.isTestAccount(email: email, password: password) else {
            try? Auth.auth().signOut()
            throw NSError(
                domain: "AuthenticationService",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Email не подтверждён. Проверьте почту и перейдите по ссылке из письма."]
            )
        }

        return User(firebaseUser: firebaseUser)
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
