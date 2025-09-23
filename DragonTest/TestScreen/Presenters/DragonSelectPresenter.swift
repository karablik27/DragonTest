//
//  DragonSelectPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

// DragonSelectPresenter.swift
import Foundation

final class DragonSelectPresenter: DragonSelectPresenterProtocol {

    private weak var view: DragonSelectViewProtocol?
    private let testService: TestServiceProtocol

    private(set) var items: [CarouselItem] = [.addButton]
    private(set) var currentIndex: Int = 0

    init(view: DragonSelectViewProtocol,
         testService: TestServiceProtocol = TestService(
            dataBase: DependencyInjection.shared.dataBase,
            currentUser: DependencyInjection.shared.currentUser
         )) {
        self.view = view
        self.testService = testService
    }


    func viewDidLoad() {
        Task { @MainActor in
            await DependencyInjection.shared.dragonCache.preload()
            loadTests()
        }
    }

    private func loadTests() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let tests = try await testService.fetchTests()
                self.items = [.addButton] + tests.map { .test($0) }
                self.currentIndex = min(self.currentIndex, self.items.count - 1)
                await MainActor.run {
                    self.view?.updateUI(items: self.items, currentIndex: self.currentIndex)
                }
            } catch {
                print("Ошибка загрузки тестов: \(error)")
            }
        }
    }


    func didSelectNext() {
        guard currentIndex < items.count - 1 else { return }
        currentIndex += 1
        view?.animateCarousel(direction: 1, newIndex: currentIndex, items: items)
    }

    func didSelectPrev() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        view?.animateCarousel(direction: -1, newIndex: currentIndex, items: items)
    }

    func didTapAdd() {
        view?.openAddTest()
    }

    func didHoldStartTest() {
        guard case let .test(test) = items[currentIndex] else { return }
        view?.openTest(test)
    }

    func didFinishTest(completed: Int) {
        if case .test(let test) = items[currentIndex] {
            print("✅ Тест \(test.title) завершён. Ответов: \(completed)")
        }
    }

    func didCreateTest(_ test: Test) {
        // уже сохранён в сервисе, просто добавим в ленту
        items.append(.test(test))
        currentIndex = items.count - 1
        view?.updateUI(items: items, currentIndex: currentIndex)
    }
}
