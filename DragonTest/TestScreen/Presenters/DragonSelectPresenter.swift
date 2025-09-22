//
//  DragonSelectPresenter.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import Foundation


final class DragonSelectPresenter: DragonSelectPresenterProtocol {

    private weak var view: DragonSelectViewProtocol?
    private let testService: MockTestService // можно заменить на TestServiceProtocol

    private(set) var items: [CarouselItem] = [.addButton]
    private(set) var currentIndex: Int = 0

    init(view: DragonSelectViewProtocol,
         testService: MockTestService = .shared) {
        self.view = view
        self.testService = testService
    }

    func viewDidLoad() {
        Task { @MainActor in
            await DragonCache.shared.preload()
            view?.updateUI(items: items, currentIndex: currentIndex)
        }
    }

    func didSelectNext() {
        guard currentIndex < items.count - 1 else { return }
        let newIndex = currentIndex + 1
        currentIndex = newIndex
        view?.animateCarousel(direction: 1, newIndex: newIndex, items: items)
    }

    func didSelectPrev() {
        guard currentIndex > 0 else { return }
        let newIndex = currentIndex - 1
        currentIndex = newIndex
        view?.animateCarousel(direction: -1, newIndex: newIndex, items: items)
    }

    func didTapAdd() {
        let test = testService.randomTest()
        items.append(.test(test))
        currentIndex = items.count - 1
        view?.updateUI(items: items, currentIndex: currentIndex)
    }

    func didHoldStartTest() {
        guard case let .test(test) = items[currentIndex] else { return }
        view?.openTest(test)
    }

    func didFinishTest(completed: Int) {
        if case .test(var test) = items[currentIndex] {
            test.completed = completed
            items[currentIndex] = .test(test)
        }
        view?.updateUI(items: items, currentIndex: currentIndex)
    }
}
