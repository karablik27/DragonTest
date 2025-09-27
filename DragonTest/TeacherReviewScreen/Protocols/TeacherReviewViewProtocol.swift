//
//  TeacherReviewViewProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//


protocol TeacherReviewViewProtocol: AnyObject {
    func showStudents(_ rows: [StudentRowModel])
    func showError(_ message: String)
}

