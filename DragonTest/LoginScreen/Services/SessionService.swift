import Foundation
import FirebaseFirestore
import FirebaseAuth

final class SessionService: SessionServiceProtocol {
    private let db: Firestore
    
    init(dataBase: Firestore) {
        self.db = dataBase
    }

    func startSession(uid: String, deviceId: String, force: Bool) async throws -> String {
        let ref = db.collection("sessions").document(uid)

        let snap = try await ref.getDocument()
        if let data = snap.data(),
           let active = data["activeDeviceId"] as? String,
           active != deviceId {
            // Уже занято другим устройством
            throw SessionError.conflict
        }

        do {
            try await ref.setData([
                "activeDeviceId": deviceId,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            let ns = error as NSError
            // Firestore permission-denied = код 7
            if ns.code == 7 {
                throw SessionError.conflict
            }
            throw error
        }

        return deviceId // в этой схеме используем deviceId как sessionId
    }

    func endSession(uid: String, deviceId: String) async {
        let ref = db.collection("sessions").document(uid)
        do {
            let snap = try await ref.getDocument()
            let active = snap.data()?["activeDeviceId"] as? String
            if active == deviceId {
                try await ref.delete()
            }
        } catch {
            // no-op
        }
    }
}
