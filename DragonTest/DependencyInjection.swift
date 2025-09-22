//
//  DependencyInjection.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import FirebaseFirestore

final class DependencyInjection {
    static let shared = DependencyInjection()
    
    let dataBase: Firestore
    let userService: UserServiceProtocol
    let authentication: AuthenticationServiceProtocol
    var currentUser: CurrentUserServiceProtocol
    
    private init() {
        self.dataBase = Firestore.firestore()
        self.userService = UserService()
        self.authentication = AuthenticationService()
        self.currentUser = CurrentUserService()
    }
}
