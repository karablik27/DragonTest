//
//  Topic.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation

struct Topic: Codable, Identifiable {
    var id: String          // "t1"
    var title: String       // "Управление памятью"
    var questions: [Questions]? // подгружаем из Firestore при необходимости
}
