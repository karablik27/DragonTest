//
//  AppNotifications.swift
//  DragonTest
//

import Foundation

extension Notification.Name {
    static let attemptReviewDidChange = Notification.Name("attemptReviewDidChange")
}

enum AttemptNotificationUserInfoKey {
    static let attemptId = "attemptId"
    static let testId = "testId"
    static let studentId = "studentId"
}
