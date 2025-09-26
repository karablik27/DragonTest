//
//  DragonTestPresenterProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 26.09.2025.
//

protocol DragonTestPresenterProtocol {
    var questionsCount: Int { get }
    var currentIndex: Int { get }
    var answered: [Bool] { get } 
    func viewDidLoad()
    func answerSelected(index: Int?)
    func textAnswerSubmitted(text: String?)
    func questionTapped(at index: Int)
    func forceFinishTest()
}
