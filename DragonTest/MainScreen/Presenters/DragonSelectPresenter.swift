//
//  DragonSelectPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation
import UIKit

final class DragonSelectPresenter: DragonSelectPresenterProtocol {

    private weak var view: DragonSelectViewProtocol?
    private let di = DependencyInjection.shared

    private(set) var items: [CarouselItem] = []
    private(set) var currentIndex: Int = 0

    init(view: DragonSelectViewProtocol) {
        self.view = view
    }

    func viewDidLoad() {
        Task { @MainActor in
            await di.dragonCache.preload()
            loadTests()
        }
    }

    private func loadTests() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let tests = try await di.testService.fetchTests()
                
                if di.currentUser.role == .teacher {
                    self.items = [.addButton] + tests.map { .test($0) }
                } else {
                    let studentId = di.currentUser.userId ?? ""
                    let studentTests = tests.filter { $0.studentIds.contains(studentId) }
                    await MainActor.run {
                        if studentTests.isEmpty {
                            self.view?.showEmptyState()
                        } else {
                            self.items = studentTests.map { .test($0) }
                            self.currentIndex = min(self.currentIndex, self.items.count - 1)
                            self.view?.updateUI(items: self.items, currentIndex: self.currentIndex)
                        }
                    }
                    // запрос статуса уедет из updateUI -> requestStatus
                    return
                }

                self.currentIndex = min(self.currentIndex, self.items.count - 1)
                await MainActor.run {
                    self.view?.updateUI(items: self.items, currentIndex: self.currentIndex)
                }
                // статус — по требованию из view.updateUI
            } catch {
                print("Ошибка загрузки тестов: \(error)")
            }
        }
    }

    // MARK: - Status
    func requestStatus(for index: Int) {
        guard index >= 0, index < items.count else { return }
        let item = items[index]
        switch item {
        case .addButton:
            view?.updateStatus("Создайте новый тест")
        case .test(let test):
            Task {
                if di.currentUser.role == .student {
                    let studentId = di.currentUser.userId ?? ""
                    do {
                        let attempt = try await di.resultService.fetchAttempt(testId: test.id, studentId: studentId)
                        let text = (attempt != nil) ? "Статус: пройдено" : "Статус: не пройдено"
                        await MainActor.run { self.view?.updateStatus(text) }
                    } catch {
                        await MainActor.run { self.view?.updateStatus("Статус: неизвестно") }
                    }
                } else {
                    // учитель: сколько учеников прошли (уникальные studentId с попытками)
                    do {
                        let attempts = try await di.answerService.fetchAttempts(for: test.id)
                        let unique = Set(attempts.map { $0.studentId })
                        let total = test.studentIds.count
                        let text = "Прошли: \(unique.count) из \(total)"
                        await MainActor.run { self.view?.updateStatus(text) }
                    } catch {
                        await MainActor.run { self.view?.updateStatus("Прошли: —") }
                    }
                }
            }
        }
    }

    // MARK: - Navigation
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
        if di.currentUser.role == .teacher {
            view?.openAddTest()
        }
    }

    func didHoldStartTest() {
        guard case let .test(test) = items[currentIndex] else { return }
        let studentId = di.currentUser.userId ?? ""
        Task { @MainActor in
            do {
                if let attempt = try await di.resultService.fetchAttempt(testId: test.id, studentId: studentId) {
                    let colors = view?.currentGradientColors() ?? [UIColor.darkGray.cgColor, UIColor.black.cgColor]
                    let vc = StudentResultViewController(
                        test: test,
                        attempt: attempt,
                        resultService: di.resultService,
                        colors: colors
                    )
                    view?.openResult(vc)
                } else {
                    view?.openTest(test)
                }
            } catch {
                print("Ошибка проверки попытки: \(error)")
            }
        }
    }

    func didFinishTest(completed: Int) {
        if case .test = items[currentIndex] {
            Task { @MainActor in
                self.view?.updateUI(items: self.items, currentIndex: self.currentIndex)
            }
        }
    }

    func didCreateTest(_ test: Test) {
        items.append(.test(test))
        currentIndex = items.count - 1
        view?.updateUI(items: items, currentIndex: currentIndex)
    }
}
