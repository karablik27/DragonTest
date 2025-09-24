import Foundation

struct UserUpdate: Codable {
    let id: String
    var image: String?
    var name: String?
    var surname: String?
    var lastname: String?
    var email: String?
    var telegramId: String?
    var role: Role?
    var language: Language?
    var isNotificationEnabled: Bool?
    
    init(
        id: String,
        image: String? = nil,
        name: String? = nil,
        surname: String? = nil,
        lastname: String? = nil,
        email: String? = nil,
        telegramId: String? = nil,
        role: Role? = nil,
        language: Language? = nil,
        isNotificationEnabled: Bool? = nil
    ) {
        self.id = id
        self.image = image
        self.name = name
        self.surname = surname
        self.lastname = lastname
        self.email = email
        self.telegramId = telegramId
        self.role = role
        self.language = language
        self.isNotificationEnabled = isNotificationEnabled
    }
}