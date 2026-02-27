//
//  DragonSelectPresenter.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import Foundation
import UIKit

private enum StudentTestStatus: Int {
    case notPassed
    case pendingTeacherReview
    case passed

    var text: String {
        switch self {
        case .notPassed:
            return "Статус: не пройдено"
        case .pendingTeacherReview:
            return "Статус: на проверке у учителя"
        case .passed:
            return "Статус: пройдено"
        }
    }
}

private enum StudentStatusFilter: Int {
    case all = 0
    case notPassed = 1
    case passed = 2
    case pendingTeacherReview = 3

    func matches(_ status: StudentTestStatus) -> Bool {
        switch self {
        case .all:
            return true
        case .notPassed:
            return status == .notPassed
        case .passed:
            return status == .passed
        case .pendingTeacherReview:
            return status == .pendingTeacherReview
        }
    }
}

@MainActor
final class DragonSelectPresenter: DragonSelectPresenterProtocol {

    private weak var view: DragonSelectViewProtocol?
    private let di = DependencyInjection.shared

    private(set) var items: [CarouselItem] = []
    private(set) var currentIndex: Int = 0

    private var allTests: [Test] = []
    private var studentStatusByTestId: [String: StudentTestStatus] = [:]
    private var statusTextByTestId: [String: String] = [:]
    private var teacherStatusTasks: [String: Task<Void, Never>] = [:]
    private var teacherPrefetchTask: Task<Void, Never>?
    private var isTeacherPrefetching = false

    private var statusFilter: StudentStatusFilter = .all

    init(view: DragonSelectViewProtocol) {
        self.view = view
    }

    func viewDidLoad() {
        Task {
            await di.dragonCache.preload()
            await loadTests()
        }
    }

    private func loadTests() async {
        do {
            let tests = try await di.testService.fetchTests()

            allTests = tests
            currentIndex = 0
            studentStatusByTestId.removeAll(keepingCapacity: true)
            statusTextByTestId.removeAll(keepingCapacity: true)
            teacherStatusTasks.values.forEach { $0.cancel() }
            teacherStatusTasks.removeAll(keepingCapacity: true)
            teacherPrefetchTask?.cancel()
            teacherPrefetchTask = nil

            if di.currentUser.role == .student {
                let studentId = di.currentUser.userId ?? ""
                do {
                    let attempts = try await di.resultService.fetchAttempts(studentId: studentId)
                    buildStudentStatuses(for: tests, attempts: attempts)
                } catch {
                    for test in tests {
                        studentStatusByTestId[test.id] = .notPassed
                        statusTextByTestId[test.id] = StudentTestStatus.notPassed.text
                    }
                }
            }

            applyFiltersAndRefresh(resetIndex: true)

            if di.currentUser.role == .teacher {
                prefetchTeacherStatuses(for: tests)
            }
        } catch {
            print("Ошибка загрузки тестов: \(error)")
        }
    }

    // MARK: - Filters
    func didChangeStatusFilter(index: Int) {
        guard di.currentUser.role == .student else { return }
        guard let selected = StudentStatusFilter(rawValue: index) else { return }
        statusFilter = selected
        applyFiltersAndRefresh(resetIndex: true)
    }

    private func applyFiltersAndRefresh(resetIndex: Bool = false) {
        let filtered = filteredAndSortedTests()

        if di.currentUser.role == .teacher {
            items = [.addButton] + filtered.map { .test($0) }
        } else {
            items = filtered.map { .test($0) }
        }

        guard !items.isEmpty else {
            currentIndex = 0
            view?.showEmptyState()
            return
        }

        if resetIndex {
            currentIndex = 0
        } else {
            currentIndex = min(currentIndex, items.count - 1)
        }

        view?.updateUI(items: items, currentIndex: currentIndex)
    }

    private func filteredAndSortedTests() -> [Test] {
        let filtered = allTests.filter { matchesStatusFilter($0) }

        return filtered.sorted { lhs, rhs in
            let lhsDate = lhs.time ?? .distantPast
            let rhsDate = rhs.time ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }

            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    private func matchesStatusFilter(_ test: Test) -> Bool {
        guard di.currentUser.role == .student else { return true }
        let status = studentStatusByTestId[test.id] ?? .notPassed
        return statusFilter.matches(status)
    }

    private func buildStudentStatuses(for tests: [Test], attempts: [StudentAttempt]) {
        let attemptsByTest = Dictionary(grouping: attempts, by: { $0.testId })

        for test in tests {
            let latestAttempt = attemptsByTest[test.id]?.max(by: { $0.submittedAt < $1.submittedAt })
            let status: StudentTestStatus
            if let latestAttempt {
                status = latestAttempt.reviewed ? .passed : .pendingTeacherReview
            } else {
                status = .notPassed
            }

            studentStatusByTestId[test.id] = status
            statusTextByTestId[test.id] = status.text
        }
    }

    // MARK: - Status
    func requestStatus(for index: Int) {
        guard index >= 0, index < items.count else { return }

        switch items[index] {
        case .addButton:
            view?.updateStatus("Создайте новый тест")

        case .test(let test):
            if let cached = statusTextByTestId[test.id] {
                view?.updateStatus(cached)
                return
            }

            if di.currentUser.role == .teacher {
                view?.updateStatus(teacherPlaceholderStatus(total: test.studentIds.count))
                if isTeacherPrefetching { return }
                fetchTeacherStatusIfNeeded(for: test)
            } else {
                let fallback = StudentTestStatus.notPassed.text
                statusTextByTestId[test.id] = fallback
                view?.updateStatus(fallback)
            }
        }
    }

    private func fetchTeacherStatusIfNeeded(for test: Test) {
        guard teacherStatusTasks[test.id] == nil else { return }

        teacherStatusTasks[test.id] = Task { [weak self] in
            guard let self else { return }
            defer { self.teacherStatusTasks[test.id] = nil }

            do {
                let summaries = try await self.di.answerService.fetchTeacherStatusSummary(for: [test.id])
                let summary = summaries[test.id] ?? TeacherTestStatusSummary(uniqueStudentsCount: 0, pendingStudentsCount: 0)
                let text = self.teacherStatusText(
                    uniqueStudents: summary.uniqueStudentsCount,
                    pendingStudents: summary.pendingStudentsCount,
                    total: test.studentIds.count
                )

                self.statusTextByTestId[test.id] = text

                if self.currentIndex >= 0,
                   self.currentIndex < self.items.count,
                   case let .test(currentTest) = self.items[self.currentIndex],
                   currentTest.id == test.id {
                    self.view?.updateStatus(text)
                }
            } catch {
                let text = self.teacherPlaceholderStatus(total: test.studentIds.count)
                self.statusTextByTestId[test.id] = text

                if self.currentIndex >= 0,
                   self.currentIndex < self.items.count,
                   case let .test(currentTest) = self.items[self.currentIndex],
                   currentTest.id == test.id {
                    self.view?.updateStatus(text)
                }
            }
        }
    }

    private func prefetchTeacherStatuses(for tests: [Test]) {
        var testsById: [String: Test] = [:]
        for test in tests {
            testsById[test.id] = test
        }
        guard !testsById.isEmpty else { return }

        teacherPrefetchTask?.cancel()
        isTeacherPrefetching = true
        teacherPrefetchTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isTeacherPrefetching = false }
            do {
                let summaries = try await self.di.answerService.fetchTeacherStatusSummary(for: Array(testsById.keys))
                if Task.isCancelled { return }

                for (testId, test) in testsById {
                    let summary = summaries[testId] ?? TeacherTestStatusSummary(uniqueStudentsCount: 0, pendingStudentsCount: 0)
                    self.statusTextByTestId[testId] = self.teacherStatusText(
                        uniqueStudents: summary.uniqueStudentsCount,
                        pendingStudents: summary.pendingStudentsCount,
                        total: test.studentIds.count
                    )
                }

                self.refreshCurrentTeacherStatusIfNeeded()
            } catch {}
        }
    }

    private func refreshCurrentTeacherStatusIfNeeded() {
        guard currentIndex >= 0, currentIndex < items.count else { return }
        guard case let .test(test) = items[currentIndex] else { return }
        guard let text = statusTextByTestId[test.id] else { return }
        view?.updateStatus(text)
    }

    private func teacherPlaceholderStatus(total: Int) -> String {
        "Прошли: — из \(total)"
    }

    private func teacherStatusText(uniqueStudents: Int, pendingStudents: Int, total: Int) -> String {
        if pendingStudents == 0 {
            return "Прошли: \(uniqueStudents) из \(total)"
        }
        return "На проверке: \(pendingStudents) • Прошли: \(uniqueStudents) из \(total)"
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
        guard currentIndex >= 0, currentIndex < items.count else { return }
        guard case let .test(test) = items[currentIndex] else { return }

        if di.currentUser.role == .teacher {
            view?.openTest(test)
            return
        }

        let studentId = di.currentUser.userId ?? ""
        Task {
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
        guard currentIndex >= 0, currentIndex < items.count else { return }
        guard case let .test(test) = items[currentIndex] else { return }

        if di.currentUser.role == .student {
            studentStatusByTestId[test.id] = .pendingTeacherReview
            statusTextByTestId[test.id] = StudentTestStatus.pendingTeacherReview.text
            applyFiltersAndRefresh()
        } else {
            view?.updateUI(items: items, currentIndex: currentIndex)
        }
    }

    func didCreateTest(_ test: Test) {
        allTests.append(test)

        if di.currentUser.role == .student {
            studentStatusByTestId[test.id] = .notPassed
            statusTextByTestId[test.id] = StudentTestStatus.notPassed.text
        } else {
            statusTextByTestId[test.id] = teacherPlaceholderStatus(total: test.studentIds.count)
            prefetchTeacherStatuses(for: allTests)
        }

        applyFiltersAndRefresh()

        if let newIndex = items.firstIndex(where: { item in
            if case let .test(existing) = item {
                return existing.id == test.id
            }
            return false
        }) {
            currentIndex = newIndex
            view?.updateUI(items: items, currentIndex: currentIndex)
        }
    }
}
