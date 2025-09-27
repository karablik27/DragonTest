//
//  ManualTestDelegate.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

protocol ManualTestDelegate: AnyObject {
    func didFinishManualSelection(title: String, dragon: DragonKind, questions: [Questions], participants: [String])
}
