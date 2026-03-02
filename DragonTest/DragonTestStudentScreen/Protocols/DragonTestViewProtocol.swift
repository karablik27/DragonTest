//
//  DragonTestViewProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 26.09.2025.
//

protocol DragonTestViewProtocol: AnyObject {
    func showQuestion(text: String, options: [String]?, answerText: String?)
    func updateTimerLabel(text: String)
    func showPreSubmitAlert(onConfirm: @escaping () -> Void)
    func showInfoAlert(remainingExits: Int)
    func showFinishAlert(answerCount: Int)
    func showError(message: String)
}
