//
//  TeacherReviewDetailViewProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

protocol TeacherReviewDetailViewProtocol: AnyObject {
    func applyBackground(colors: [CGColor])
    func setHeader(testTitle: String)
    func showFooter(_ show: Bool)
    func setSaveEnabled(_ enabled: Bool)
    func reloadAll()
    func reloadRow(_ row: Int)
    func showMessage(title: String, message: String, onOK: (() -> Void)?)
    func pop()
}
