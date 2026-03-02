//
//  DragonSelectViewProtocol.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import UIKit

@MainActor
protocol DragonSelectViewProtocol: AnyObject {
    func updateUI(items: [CarouselItem], currentIndex: Int)
    func showEmptyState()
    func openTest(_ test: Test, resumeAttempt: StudentAttempt?)
    func openResult(_ vc: StudentResultViewController)
    func animateCarousel(direction: Int, newIndex: Int, items: [CarouselItem])
    func openAddTest()
    func currentGradientColors() -> [CGColor]
    func updateStatus(_ text: String)
    func updateDragonCapture(caught: Bool?)
}
