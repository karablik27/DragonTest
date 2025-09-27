//
//  StudentResultViewProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

protocol StudentResultViewProtocol: AnyObject {
    func setTitle(_ text: String)
    func showStatus(_ text: String)
    func showTeacherComment(_ text: String?, hidden: Bool)
    func showLLMSummary(_ text: String?, hidden: Bool)
    func reloadAnswers()
}
