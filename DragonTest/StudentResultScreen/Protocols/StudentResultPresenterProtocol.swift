//
//  StudentResultPresenterProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

protocol StudentResultPresenterProtocol: AnyObject {
    func attach(view: StudentResultViewProtocol)
    func viewDidLoad()
    func numberOfRows() -> Int
    func answer(at index: Int) -> (answer: StudentAnswer, questionText: String)?
    func closeTapped()
}
