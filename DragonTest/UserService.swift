//
//  UserService.swift
//  DragonTest
//
//  Created by Sergey on 21.09.2025.
//

import FirebaseFirestore
import FirebaseAuth

final class UserService {
    private let db = Firestore.firestore()
    
    func saveUser(_ user: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Нет текущего пользователя"])
        }
        
        try await db.collection("users").document(uid).setData(from: user)
    }
}
