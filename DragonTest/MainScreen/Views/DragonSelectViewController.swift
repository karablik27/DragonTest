//
//  DragonSelectViewController.swift
//  DragonTest
//

import UIKit
import RealityKit

// MARK: - Models

enum CarouselItem {
    case addButton
    case test(Test)
}

extension CarouselItem {
    var isTest: Bool {
        if case .test = self { return true }
        return false
    }

    var testId: String? {
        if case .test(let test) = self { return test.id }
        return nil
    }
}

final class StatusBadgeView: UIView {

    private let card: TestGlassCard
    private let stack = UIStackView()
    private let iconView = UIImageView()
    private let separator = UIView()
    private let textLabel = UILabel()

    init(radius: CGFloat = 16) {
        self.card = TestGlassCard(radius: radius)
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isOpaque = false

        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = .init(pointSize: 18, weight: .semibold)
        iconView.tintColor = .white
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])

        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        separator.widthAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        separator.layer.cornerRadius = 0.5

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        textLabel.textColor = .white
        textLabel.numberOfLines = 2

        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(separator)
        stack.addArrangedSubview(textLabel)

        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(text: String) {
        textLabel.text = text
        accessibilityLabel = text

        let lower = text.lowercased()
        if lower.contains("на проверке") {
            apply(symbol: "hourglass.badge.exclamationmark", tint: .systemYellow)
        } else if lower.contains("прошли:") {
            apply(symbol: "person.3.fill", tint: .systemTeal)
        } else if lower.contains("не пройдено") {
            apply(symbol: "xmark.seal.fill", tint: .systemOrange)
        } else if lower.contains("пройдено") {
            apply(symbol: "checkmark.seal.fill", tint: .systemGreen)
        } else {
            apply(symbol: "questionmark.circle.fill", tint: UIColor.white.withAlphaComponent(0.85))
        }
    }

    private func apply(symbol: String, tint: UIColor) {
        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = tint
        separator.backgroundColor = tint.withAlphaComponent(0.22)
        card.layer.shadowOpacity = 0.22
    }
}

// MARK: - Controller

final class DragonSelectViewController: UIViewController, DragonSelectViewProtocol {

    // MARK: - MVP
    private var presenter: DragonSelectPresenterProtocol!

    // MARK: - Data
    private var items: [CarouselItem] = []
    private var currentIndex = 0
    private var testVC: DragonTestViewController?
    private var teacherVC: TeacherReviewViewController?
    private var resultVC: StudentResultViewController?
    private var isTestVisible = false
    private var preloadedStudentTestId: String?
    private var preloadedTeacherTestId: String?

    // Hold
    private var holdTimer: Timer?
    private var holdProgress: CGFloat = 0.0
    private let holdDuration: TimeInterval = 5.0

    // MARK: - UI
    private let testContainer = UIView()
    private let dragonsContainer = UIView()

    private let gradientHost = UIView()
    private let bgLayer = CAGradientLayer()

    private let statusFilterButton = UIButton(type: .system)
    private var selectedStatusFilterIndex = 0

    private let centerPreviewContainer = UIView()
    private let leftPreviewContainer = UIView()
    private let rightPreviewContainer = UIView()

    private let centerDragonPreview = DragonPreviewView()
    private let leftDragonPreview = DragonPreviewView()
    private let rightDragonPreview = DragonPreviewView()
    private let centerAddPreview = AddButtonPreviewView()
    private let leftAddPreview = AddButtonPreviewView()
    private let rightAddPreview = AddButtonPreviewView()
    private var renderedPreviewKeys: [ObjectIdentifier: String] = [:]

    private let titleLabel = UILabel()
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    private let hintView = SwipeUpHintView()
    private var currentColors: [CGColor] = [UIColor.darkGray.cgColor, UIColor.black.cgColor]

    private let emptyStateView = EmptyStateView(message: "Нет доступных тестов")
    private let statusBadge = StatusBadgeView(radius: 18)

    // Legacy widgets (hidden)
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()

        presenter = DragonSelectPresenter(view: self)
        presenter.viewDidLoad()

        addGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgLayer.frame = gradientHost.bounds
    }

    func currentGradientColors() -> [CGColor] { currentColors }

    // MARK: - DragonSelectViewProtocol
    func updateUI(items: [CarouselItem], currentIndex: Int) {
        guard !items.isEmpty, currentIndex >= 0, currentIndex < items.count else {
            showEmptyState()
            return
        }

        let previousItem = (self.currentIndex >= 0 && self.currentIndex < self.items.count) ? self.items[self.currentIndex] : nil

        self.items = items
        self.currentIndex = currentIndex

        emptyStateView.isHidden = true
        dragonsContainer.isHidden = false
        centerPreviewContainer.isHidden = false
        leftPreviewContainer.isHidden = false
        rightPreviewContainer.isHidden = false
        titleLabel.isHidden = false

        let item = items[currentIndex]
        resetPreloadedControllersIfNeeded(from: previousItem, to: item)

        applyGradient(for: item, animated: false)

        configure(
            container: centerPreviewContainer,
            dragonPreview: centerDragonPreview,
            addPreview: centerAddPreview,
            item: item,
            scale: [0.8, 0.8, 0.8]
        )
        configure(
            container: leftPreviewContainer,
            dragonPreview: leftDragonPreview,
            addPreview: leftAddPreview,
            item: currentIndex > 0 ? items[currentIndex - 1] : nil,
            scale: [0.6, 0.6, 0.6]
        )
        configure(
            container: rightPreviewContainer,
            dragonPreview: rightDragonPreview,
            addPreview: rightAddPreview,
            item: currentIndex < items.count - 1 ? items[currentIndex + 1] : nil,
            scale: [0.6, 0.6, 0.6]
        )

        titleLabel.text = titleForItem(item)
        prevButton.isHidden = currentIndex == 0
        nextButton.isHidden = currentIndex == items.count - 1

        progressView.isHidden = true
        progressLabel.isHidden = true
        statusBadge.isHidden = false
        hintView.isHidden = !item.isTest

        presenter.requestStatus(for: currentIndex)
    }

    func updateStatus(_ text: String) {
        UIView.transition(with: statusBadge, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusBadge.update(text: text)
        }
    }

    func showEmptyState() {
        dragonsContainer.isHidden = false
        emptyStateView.isHidden = false
        centerPreviewContainer.isHidden = true
        leftPreviewContainer.isHidden = true
        rightPreviewContainer.isHidden = true
        titleLabel.isHidden = true
        prevButton.isHidden = true
        nextButton.isHidden = true
        statusBadge.isHidden = true
        hintView.isHidden = true
    }

    func openTest(_ test: Test) {
        guard !isTestVisible else { return }

        if DependencyInjection.shared.currentUser.role == .student {
            if preloadedStudentTestId != test.id {
                testVC = nil
                preloadedStudentTestId = nil
            }

            if testVC == nil {
                testVC = DragonTestViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                ) { [weak self] completed in
                    self?.presenter.didFinishTest(completed: completed)
                    self?.closeTest()
                }
                preloadedStudentTestId = test.id
                _ = testVC?.view
                testVC?.view.layoutIfNeeded()
            }

            if let vc = testVC {
                addChild(vc)
                testContainer.addSubview(vc.view)
                vc.view.frame = testContainer.bounds
                vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                vc.didMove(toParent: self)
            }
        } else {
            if preloadedTeacherTestId != test.id {
                teacherVC = nil
                preloadedTeacherTestId = nil
            }

            if teacherVC == nil {
                let vc = TeacherReviewViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                )
                vc.onClose = { [weak self] in self?.closeTest() }
                teacherVC = vc
                preloadedTeacherTestId = test.id
                _ = vc.view
                vc.view.layoutIfNeeded()
            }

            if let vc = teacherVC {
                let nav = UINavigationController(rootViewController: vc)
                addChild(nav)
                testContainer.addSubview(nav.view)
                nav.view.frame = testContainer.bounds
                nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                nav.didMove(toParent: self)
            }
        }

        testContainer.alpha = 1
        animateOpen()
    }

    func openResult(_ vc: StudentResultViewController) {
        guard !isTestVisible else { return }

        resultVC = vc
        vc.onClose = { [weak self] in self?.closeTest() }

        let nav = UINavigationController(rootViewController: vc)
        addChild(nav)
        testContainer.addSubview(nav.view)
        nav.view.frame = testContainer.bounds
        nav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        nav.didMove(toParent: self)

        testContainer.alpha = 1
        animateOpen()
    }

    // MARK: - Animations
    private func animateOpen() {
        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut],
                       animations: {
            self.dragonsContainer.transform = CGAffineTransform(translationX: 0, y: -self.view.bounds.height)
        }, completion: { _ in
            self.isTestVisible = true
        })
    }

    func animateCarousel(direction: Int, newIndex: Int, items: [CarouselItem]) {
        let width = view.bounds.width
        let shiftCenter = width * 0.20
        let shiftSide = width * 0.10
        let dur: TimeInterval = 0.35

        if newIndex >= 0 && newIndex < items.count {
            applyGradient(for: items[newIndex], animated: true, duration: dur)
        }

        UIView.animate(withDuration: dur, animations: {
            self.centerPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? -shiftCenter : shiftCenter, y: 0
            ).scaledBy(x: 0.9, y: 0.9)
            self.centerPreviewContainer.alpha = 0

            self.leftPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? -shiftSide : shiftSide, y: 0
            ).scaledBy(x: 0.95, y: 0.95)
            self.rightPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? -shiftSide : shiftSide, y: 0
            ).scaledBy(x: 0.95, y: 0.95)

            self.leftPreviewContainer.alpha = 0.35
            self.rightPreviewContainer.alpha = 0.35
        }, completion: { _ in
            self.updateUI(items: items, currentIndex: newIndex)
            self.centerPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? shiftCenter : -shiftCenter, y: 0
            ).scaledBy(x: 0.9, y: 0.9)
            self.centerPreviewContainer.alpha = 0

            self.leftPreviewContainer.transform = .identity
            self.rightPreviewContainer.transform = .identity

            UIView.animate(withDuration: dur) {
                self.centerPreviewContainer.transform = .identity
                self.centerPreviewContainer.alpha = 1
                self.leftPreviewContainer.alpha = 0.5
                self.rightPreviewContainer.alpha = 0.5
            }
        })
    }

    func openAddTest() {
        let addVC = AddTestViewController(testService: DependencyInjection.shared.testService)
        addVC.delegate = self
        addVC.modalPresentationStyle = .formSheet
        present(addVC, animated: true)
    }

    // MARK: - Actions
    @objc private func prevTap() { presenter.didSelectPrev() }
    @objc private func nextTap() { presenter.didSelectNext() }
    @objc private func addTap()  { presenter.didTapAdd() }

    private func applyStatusFilter(index: Int) {
        selectedStatusFilterIndex = index
        rebuildStatusFilterMenu()
        presenter.didChangeStatusFilter(index: index)
    }

    private func rebuildStatusFilterMenu() {
        let menu = UIMenu(title: "Фильтр тестов", children: [
            makeStatusFilterAction(title: "Все", index: 0),
            makeStatusFilterAction(title: "Пройдено", index: 2),
            makeStatusFilterAction(title: "Не пройдено", index: 1),
            makeStatusFilterAction(title: "На проверке", index: 3)
        ])
        statusFilterButton.menu = menu
    }

    private func makeStatusFilterAction(title: String, index: Int) -> UIAction {
        UIAction(
            title: title,
            state: selectedStatusFilterIndex == index ? .on : .off
        ) { [weak self] _ in
            self?.applyStatusFilter(index: index)
        }
    }

    // MARK: - Gestures
    private func addGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        dragonsContainer.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        dragonsContainer.addGestureRecognizer(swipeRight)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        dragonsContainer.addGestureRecognizer(longPress)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left: presenter.didSelectNext()
        case .right: presenter.didSelectPrev()
        default: break
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            holdProgress = 0
            hintView.resetProgress()
            startHoldTimer()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .ended, .cancelled, .failed:
            cancelHoldTimer()
        default: break
        }
    }

    // MARK: - Hold Timer
    private func startHoldTimer() {
        cancelHoldTimer()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.holdProgress += 0.1
            let percent = min(self.holdProgress / self.holdDuration, 1.0)
            self.hintView.updateProgress(percent)

            guard self.currentIndex >= 0,
                  self.currentIndex < self.items.count,
                  case let .test(test) = self.items[self.currentIndex] else {
                if percent >= 1.0 {
                    t.invalidate()
                }
                return
            }

            if percent >= 0.3,
               DependencyInjection.shared.currentUser.role == .student {
                if self.preloadedStudentTestId != test.id {
                    self.testVC = nil
                    self.preloadedStudentTestId = nil
                }

                if self.testVC == nil {
                    self.testVC = DragonTestViewController(
                        test: test,
                        colors: test.dragonKind.gradientColors
                    ) { [weak self] completed in
                        self?.presenter.didFinishTest(completed: completed)
                        self?.closeTest()
                    }
                    self.preloadedStudentTestId = test.id
                    _ = self.testVC?.view
                    self.testVC?.view.layoutIfNeeded()
                }
            }

            if DependencyInjection.shared.currentUser.role == .teacher,
               percent >= 0.30 {
                if self.preloadedTeacherTestId != test.id {
                    self.teacherVC = nil
                    self.preloadedTeacherTestId = nil
                }

                if self.teacherVC == nil {
                    let vc = TeacherReviewViewController(
                        test: test,
                        colors: test.dragonKind.gradientColors
                    )
                    vc.onClose = { [weak self] in self?.closeTest() }
                    self.teacherVC = vc
                    self.preloadedTeacherTestId = test.id
                    _ = vc.view
                    vc.view.layoutIfNeeded()
                }
            }

            if percent >= 1.0 {
                t.invalidate()
                self.presenter.didHoldStartTest()
            }
        }
    }

    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
        hintView.resetProgress()
        holdProgress = 0
    }

    private func closeTest() {
        guard isTestVisible else { return }

        UIView.animate(withDuration: 0.6,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.6,
                       options: [.curveEaseInOut],
                       animations: {
            self.dragonsContainer.transform = .identity
            self.testContainer.alpha = 0
        }, completion: { _ in
            if let vc = self.testVC {
                vc.willMove(toParent: nil)
                vc.view.removeFromSuperview()
                vc.removeFromParent()
                self.testVC = nil
            }
            if let vc = self.teacherVC {
                vc.willMove(toParent: nil)
                vc.view.removeFromSuperview()
                vc.removeFromParent()
                self.teacherVC = nil
            }
            if let nav = self.children.first(where: { $0 is UINavigationController }) {
                nav.willMove(toParent: nil)
                nav.view.removeFromSuperview()
                nav.removeFromParent()
            }
            self.preloadedStudentTestId = nil
            self.preloadedTeacherTestId = nil
            self.resultVC = nil
            self.isTestVisible = false
            self.testContainer.alpha = 1
            self.updateUI(items: self.items, currentIndex: self.currentIndex)
        })
    }

    private func resetPreloadedControllersIfNeeded(from previousItem: CarouselItem?, to newItem: CarouselItem) {
        guard !isTestVisible else { return }
        guard previousItem?.testId != newItem.testId else { return }

        testVC = nil
        teacherVC = nil
        preloadedStudentTestId = nil
        preloadedTeacherTestId = nil
    }

    // MARK: - UI
    private func setupUI() {
        [testContainer, dragonsContainer,
         gradientHost,
         statusFilterButton,
         centerPreviewContainer, leftPreviewContainer, rightPreviewContainer,
         centerDragonPreview, leftDragonPreview, rightDragonPreview,
         centerAddPreview, leftAddPreview, rightAddPreview,
         titleLabel, prevButton, nextButton,
         hintView, emptyStateView,
         statusBadge,
         progressView, progressLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(testContainer)
        view.addSubview(dragonsContainer)
        view.addSubview(emptyStateView)

        dragonsContainer.addSubview(gradientHost)
        NSLayoutConstraint.activate([
            gradientHost.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor),
            gradientHost.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor),
            gradientHost.topAnchor.constraint(equalTo: dragonsContainer.topAnchor),
            gradientHost.bottomAnchor.constraint(equalTo: dragonsContainer.bottomAnchor)
        ])
        bgLayer.startPoint = CGPoint(x: 0, y: 0)
        bgLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientHost.layer.addSublayer(bgLayer)
        dragonsContainer.sendSubviewToBack(gradientHost)

        dragonsContainer.addSubview(statusFilterButton)
        var menuButtonConfig = UIButton.Configuration.plain()
        menuButtonConfig.image = UIImage(systemName: "ellipsis.circle")
        menuButtonConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        statusFilterButton.configuration = menuButtonConfig
        statusFilterButton.tintColor = .white
        statusFilterButton.showsMenuAsPrimaryAction = true
        statusFilterButton.accessibilityLabel = "Фильтр тестов"
        rebuildStatusFilterMenu()

        if DependencyInjection.shared.currentUser.role == .teacher {
            statusFilterButton.isHidden = true
        }

        dragonsContainer.addSubview(centerPreviewContainer)
        dragonsContainer.addSubview(leftPreviewContainer)
        dragonsContainer.addSubview(rightPreviewContainer)
        dragonsContainer.addSubview(titleLabel)
        dragonsContainer.addSubview(prevButton)
        dragonsContainer.addSubview(nextButton)
        dragonsContainer.addSubview(statusBadge)
        dragonsContainer.addSubview(hintView)

        setupReusablePreview(
            in: centerPreviewContainer,
            dragonPreview: centerDragonPreview,
            addPreview: centerAddPreview
        )
        setupReusablePreview(
            in: leftPreviewContainer,
            dragonPreview: leftDragonPreview,
            addPreview: leftAddPreview
        )
        setupReusablePreview(
            in: rightPreviewContainer,
            dragonPreview: rightDragonPreview,
            addPreview: rightAddPreview
        )

        [centerAddPreview, leftAddPreview, rightAddPreview].forEach {
            $0.button.addTarget(self, action: #selector(addTap), for: .touchUpInside)
        }

        NSLayoutConstraint.activate([
            testContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            testContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            testContainer.topAnchor.constraint(equalTo: view.topAnchor),
            testContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dragonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dragonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dragonsContainer.topAnchor.constraint(equalTo: view.topAnchor),
            dragonsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusFilterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusFilterButton.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -14),
            statusFilterButton.widthAnchor.constraint(equalToConstant: 36),
            statusFilterButton.heightAnchor.constraint(equalToConstant: 36),

            centerPreviewContainer.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            centerPreviewContainer.centerYAnchor.constraint(equalTo: dragonsContainer.centerYAnchor, constant: -40),
            centerPreviewContainer.widthAnchor.constraint(equalTo: dragonsContainer.widthAnchor, multiplier: 0.80),
            centerPreviewContainer.heightAnchor.constraint(equalTo: centerPreviewContainer.widthAnchor),

            leftPreviewContainer.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            leftPreviewContainer.trailingAnchor.constraint(equalTo: centerPreviewContainer.leadingAnchor, constant: -20),
            leftPreviewContainer.widthAnchor.constraint(equalTo: centerPreviewContainer.widthAnchor, multiplier: 0.55),
            leftPreviewContainer.heightAnchor.constraint(equalTo: leftPreviewContainer.widthAnchor),

            rightPreviewContainer.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            rightPreviewContainer.leadingAnchor.constraint(equalTo: centerPreviewContainer.trailingAnchor, constant: 20),
            rightPreviewContainer.widthAnchor.constraint(equalTo: centerPreviewContainer.widthAnchor, multiplier: 0.55),
            rightPreviewContainer.heightAnchor.constraint(equalTo: rightPreviewContainer.widthAnchor),

            titleLabel.bottomAnchor.constraint(equalTo: centerPreviewContainer.topAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),

            prevButton.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            prevButton.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 16),

            nextButton.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -16),

            statusBadge.topAnchor.constraint(equalTo: centerPreviewContainer.bottomAnchor, constant: 16),
            statusBadge.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 40),
            statusBadge.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -40),

            hintView.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            hintView.topAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: 14),
            hintView.widthAnchor.constraint(equalToConstant: 80),
            hintView.heightAnchor.constraint(equalToConstant: 120),

            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white

        prevButton.isHidden = true
        nextButton.isHidden = true
        hintView.isHidden = true
        emptyStateView.isHidden = true
        emptyStateView.isUserInteractionEnabled = false

        progressView.isHidden = true
        progressLabel.isHidden = true

        testContainer.backgroundColor = .clear
    }

    private func setupReusablePreview(in container: UIView,
                                      dragonPreview: DragonPreviewView,
                                      addPreview: AddButtonPreviewView) {
        container.addSubview(dragonPreview)
        container.addSubview(addPreview)

        NSLayoutConstraint.activate([
            dragonPreview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dragonPreview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dragonPreview.topAnchor.constraint(equalTo: container.topAnchor),
            dragonPreview.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            addPreview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            addPreview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addPreview.topAnchor.constraint(equalTo: container.topAnchor),
            addPreview.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        dragonPreview.isHidden = true
        addPreview.isHidden = true
    }

    private func configure(container: UIView,
                           dragonPreview: DragonPreviewView,
                           addPreview: AddButtonPreviewView,
                           item: CarouselItem?,
                           scale: SIMD3<Float>) {
        let cacheKey = previewKey(for: item, scale: scale)
        let containerId = ObjectIdentifier(container)

        if renderedPreviewKeys[containerId] == cacheKey {
            return
        }
        renderedPreviewKeys[containerId] = cacheKey

        guard let item else {
            addPreview.isHidden = true
            dragonPreview.isHidden = true
            dragonPreview.clear()
            return
        }

        switch item {
        case .addButton:
            addPreview.isHidden = false
            dragonPreview.isHidden = true
            dragonPreview.clear()

        case .test(let test):
            addPreview.isHidden = true
            dragonPreview.isHidden = false
            if let entity = DependencyInjection.shared.dragonCache.clone(for: test.dragonKind, scale: scale) {
                dragonPreview.displayEntity(entity, animated: container === centerPreviewContainer)
            } else {
                dragonPreview.clear()
            }
        }
    }

    private func previewKey(for item: CarouselItem?, scale: SIMD3<Float>) -> String {
        guard let item else { return "none" }
        switch item {
        case .addButton:
            return "add"
        case .test(let test):
            return "\(test.id)-\(scale.x)-\(scale.y)-\(scale.z)"
        }
    }

    private func titleForItem(_ item: CarouselItem) -> String {
        switch item {
        case .addButton: return "Добавить дракона"
        case .test(let test): return test.title
        }
    }

    private func gradientForItem(_ item: CarouselItem) -> [CGColor] {
        switch item {
        case .addButton: return [UIColor.darkGray.cgColor, UIColor.black.cgColor]
        case .test(let test): return test.dragonKind.gradientColors
        }
    }

    private func applyGradient(for item: CarouselItem, animated: Bool, duration: TimeInterval = 0.35) {
        let colors = gradientForItem(item)
        if animated, let from = bgLayer.colors {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = from
            anim.toValue = colors
            anim.duration = duration
            bgLayer.add(anim, forKey: "colors")
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bgLayer.colors = colors
        CATransaction.commit()
        currentColors = colors
    }

    private func makeArrowButton(_ title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        b.tintColor = .white
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }
}

// MARK: - AddTestDelegate
extension DragonSelectViewController: AddTestDelegate {
    func didFinishManualSelection(
        title: String,
        dragon: DragonKind,
        questions: [Questions],
        participants: [String]
    ) {
        let newTest = Test(
            id: UUID().uuidString,
            title: title,
            dragonKind: dragon,
            questions: questions,
            teacherId: CurrentUserService().userId ?? "unknown",
            studentIds: participants,
            time: Date()
        )
        presenter.didCreateTest(newTest)
    }

    func didCreateTest(_ test: Test) {
        presenter.didCreateTest(test)
    }
}
