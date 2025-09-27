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
        return User(firebaseUser: authDataResult.user)
    }
    
    func signInUser(email: String, password: String) async throws -> User {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return User(firebaseUser: authDataResult.user)
    }
}
