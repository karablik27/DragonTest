//
//  DeviceIdProvider.swift
//  DragonTest
//
//  Created by Крючков Сергей on 23.09.2025.
//

import Foundation

final class DeviceIdProvider {
    static let shared = DeviceIdProvider()

    private let key = "persistent_device_id"
    private(set) var deviceId: String

    private init() {
        if let data = KeychainStorage.load(for: key),
           let str = String(data: data, encoding: .utf8) {
            deviceId = str
        } else {
            let newId = UUID().uuidString
            _ = KeychainStorage.save(Data(newId.utf8), for: key)
            deviceId = newId
        }
    }
}
