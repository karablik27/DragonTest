//
//  ProfileViewProtocol.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit

protocol ProfileViewProtocol: AnyObject {
    func setWelcomeName(_ name: String)
    func setAvatar(_ image: UIImage)
    func setAvatarPlaceholder()
    func setNotifications(_ items: [String])
    func setStats(_ vm: ProfileStatsViewModel)
    func setActivityDates(student: Set<String>, teacher: Set<String>)
    func reloadCalendar()
    func setRating(_ items: [RatingItem], avatars: [String: UIImage])
    func showAlert(title: String, message: String)
}
