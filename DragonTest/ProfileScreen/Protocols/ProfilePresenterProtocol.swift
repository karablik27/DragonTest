//
//  ProfilePresenterProtocol.swift
//  DragonTest
//
//  Created by Крючков Сергей on 27.09.2025.
//

protocol ProfilePresenterProtocol: AnyObject {
    func attach(view: ProfileViewProtocol)
    func viewDidLoad()
    func viewWillDisappear()
    func didTapBell()
    func clearNotifications()
    func calendarViewChanged(isWeekView: Bool)
}
