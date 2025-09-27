//
//  TeacherReviewDetailPresenterProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

protocol TeacherReviewDetailPresenterProtocol: AnyObject {
    func attach(view: TeacherReviewDetailViewProtocol)
    func viewDidLoad()
    func numberOfRows() -> Int
    func item(at index: Int) -> (answer: StudentAnswer, questionText: String, isEditable: Bool)
    func didUpdateAnswer(at index: Int, to answer: StudentAnswer)
    func saveTapped()
}
