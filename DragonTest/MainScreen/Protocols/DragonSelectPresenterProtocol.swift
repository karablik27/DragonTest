//
//  DragonSelectPresenterProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import Foundation

protocol DragonSelectPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didSelectNext()
    func didSelectPrev()
    func didTapAdd()
    func didHoldStartTest()
    func didFinishTest(completed: Int)
}
