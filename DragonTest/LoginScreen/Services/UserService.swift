//
//  UserService.swift
//  DragonTest
//
//  Created by Sergey on 21.09.2025.
//

import FirebaseFirestore
import FirebaseAuth

final class UserService: UserServiceProtocol {
    private let dataBase: Firestore

    init(dataBase: Firestore) {
        self.dataBase = dataBase
    }

    func saveUser(_ user: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserService",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "errors.no_current_user".localized])
        }

        try dataBase.collection("users").document(uid).setData(from: user)
    }
    
    func updateUser(_ userUpdate: UserUpdate) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserService",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "errors.no_current_user".localized])
        }
        try await dataBase.collection("users").document(uid).setData(from: userUpdate, merge: true)
    }
    
    func updateEmail(_ newEmail: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "errors.no_current_user".localized])
        }
        
        try await currentUser.updateEmail(to: newEmail)
        
        let update = UserUpdate(id: currentUser.uid, email: newEmail)
        try await updateUser(update)
    }
    
    func updatePassword(_ newPassword: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "UserService", code: 0, userInfo: [NSLocalizedDescriptionKey: "errors.no_current_user".localized])
        }
        
        try await currentUser.updatePassword(to: newPassword)
    }

    func fetchUser(uid: String) async throws -> User {
        let snapshot = try await dataBase.collection("users").document(uid).getDocument()
        guard let data = snapshot.data() else {
            throw NSError(domain: "UserService",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "errors.user_not_found_firestore".localized])
        }
        return try Firestore.Decoder().decode(User.self, from: data)
    }
    
    func fetchStudentsForTests(for test: Test) async throws -> [User] {
            guard !test.studentIds.isEmpty else { return [] }
            let chunked = test.studentIds.chunked(into: 10)
            var result: [User] = []

            for ids in chunked {
                let snapshot = try await dataBase.collection("users")
                    .whereField(FieldPath.documentID(), in: ids)
                    .getDocuments()
                
                let users = try snapshot.documents.compactMap { doc -> User? in
                    try? doc.data(as: User.self)
                }
                result.append(contentsOf: users)
            }
            return result
        }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
