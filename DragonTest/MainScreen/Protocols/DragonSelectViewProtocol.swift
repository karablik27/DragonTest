//
//  DragonSelectViewProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import UIKit

protocol DragonSelectViewProtocol: AnyObject {
    func updateUI(items: [CarouselItem], currentIndex: Int)
    func animateCarousel(direction: Int, newIndex: Int, items: [CarouselItem])
    func openAddTest()
    func openTest(_ test: Test)
    func showEmptyState()
    func openResult(_ vc: StudentResultViewController)
    func currentGradientColors() -> [CGColor]
}

