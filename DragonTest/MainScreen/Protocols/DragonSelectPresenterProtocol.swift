//
//  DragonSelectPresenterProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation

@MainActor
protocol DragonSelectPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectNext()
    func didSelectPrev()
    func didTapAdd()
    func didHoldStartTest()
    func didFinishTest(completed: Int)
    func didCreateTest(_ test: Test)
    func requestStatus(for index: Int)
    func didChangeStatusFilter(index: Int)
    func refreshStatuses()
}
