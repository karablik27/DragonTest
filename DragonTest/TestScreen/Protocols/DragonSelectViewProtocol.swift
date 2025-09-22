//
//  DragonSelectViewProtocol.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

protocol DragonSelectViewProtocol: AnyObject {
    func updateUI(items: [CarouselItem], currentIndex: Int)
    func openTest(_ test: Test)
    func animateCarousel(direction: Int, newIndex: Int, items: [CarouselItem])
    func openAddTest()
}
