//
//  DependencyInjection.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import FirebaseFirestore

final class DependencyInjection {
    static let shared = DependencyInjection()
    
    var currentUser: CurrentUserServiceProtocol
    let dragonCache: DragonCache
    let dataBase: Firestore
    let userService: UserServiceProtocol
    let authentication: AuthenticationServiceProtocol
    let testService: TestServiceProtocol
    let answerService: AnswerServiceProtocol
    let sessionService: SessionServiceProtocol = SessionService()
    
    private init() {
        self.currentUser = CurrentUserService()
        self.dragonCache = DragonCache()
        self.dataBase = Firestore.firestore()
        self.userService = UserService(dataBase: self.dataBase) 
        self.authentication = AuthenticationService()
        self.testService = TestService(dataBase: self.dataBase, currentUser: self.currentUser)
        self.answerService = AnswerService(dataBase: Firestore.firestore())
        self.sessionService = SessionService()
    }
}
