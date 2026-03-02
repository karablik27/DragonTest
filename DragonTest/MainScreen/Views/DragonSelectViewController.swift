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
    private let titleLabel = UILabel()
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

        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
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

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        titleLabel.textAlignment = .center
        titleLabel.text = "Статус"
        titleLabel.numberOfLines = 1

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        textLabel.textColor = .white
        textLabel.numberOfLines = 3
        textLabel.textAlignment = .center

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(textLabel)

        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(text: String) {
        textLabel.text = text
        accessibilityLabel = "Статус: \(text)"
        applyAccent(for: text)
    }

    private func applyAccent(for text: String) {
        let lower = text.lowercased()
        let tint: UIColor
        if lower.contains("ии проверяет") || lower.contains("ждём учителя") || lower.contains("на проверке") {
            tint = .systemYellow
        } else if lower.contains("проверено учителем") || lower.contains("прошли:") || lower.contains("пройдено") {
            tint = .systemGreen
        } else if lower.contains("не пройдено") {
            tint = .systemOrange
        } else {
            tint = UIColor.white.withAlphaComponent(0.85)
        }

        titleLabel.textColor = tint.withAlphaComponent(0.92)
        card.layer.shadowOpacity = 0.22
    }
}

final class DragonCaptureBadgeView: UIControl {
    private let card = TestGlassCard(radius: 14)
    private let valueLabel = UILabel()
    private let iconView = UIImageView(image: UIImage(systemName: "flame.fill"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = false
        addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = UIColor(red: 1.0, green: 0.79, blue: 0.22, alpha: 1.0)
        iconView.preferredSymbolConfiguration = .init(pointSize: 18, weight: .semibold)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 26, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.text = "0/1"
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.65
        valueLabel.lineBreakMode = .byClipping
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        card.addSubview(iconView)
        card.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            valueLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(caught: Bool) {
        valueLabel.text = caught ? "1/1" : "0/1"
        accessibilityLabel = "Пойман дракон \(caught ? "1 из 1" : "0 из 1")"
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
    private var isDragonScreenVisible = false
    private var didSetupStatusObservers = false

    private let titleLabel = UILabel()
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    private let hintView = SwipeUpHintView()
    private var currentColors: [CGColor] = [UIColor.darkGray.cgColor, UIColor.black.cgColor]

    private let emptyStateView = EmptyStateView(message: "Нет доступных тестов")
    private let dragonCaptureBadge = DragonCaptureBadgeView()
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDragonScreenVisible = true
        refreshDragonPreviews()

        if !didSetupStatusObservers {
            didSetupStatusObservers = true
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAppDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAttemptReviewDidChange(_:)),
                name: .attemptReviewDidChange,
                object: nil
            )
        }

        presenter.refreshStatuses()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isDragonScreenVisible = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func currentGradientColors() -> [CGColor] { currentColors }

    @objc private func handleAppDidBecomeActive() {
        presenter.refreshStatuses()
    }

    @objc private func handleAttemptReviewDidChange(_ note: Notification) {
        guard DependencyInjection.shared.currentUser.role == .student else { return }
        let currentStudentId = DependencyInjection.shared.currentUser.userId ?? ""

        if let studentId = note.userInfo?[AttemptNotificationUserInfoKey.studentId] as? String,
           !studentId.isEmpty,
           studentId != currentStudentId {
            return
        }

        presenter.refreshStatuses()
    }

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
        dragonCaptureBadge.isHidden = DependencyInjection.shared.currentUser.role != .student || !item.isTest
        hintView.isHidden = !item.isTest

        presenter.requestStatus(for: currentIndex)
    }

    func updateStatus(_ text: String) {
        UIView.transition(with: statusBadge, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusBadge.update(text: text)
        }
    }

    func updateDragonCapture(caught: Bool?) {
        guard let caught else {
            dragonCaptureBadge.isHidden = true
            return
        }
        dragonCaptureBadge.update(caught: caught)
        dragonCaptureBadge.isHidden = false
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
        dragonCaptureBadge.isHidden = true
        hintView.isHidden = true
    }

    func openTest(_ test: Test, resumeAttempt: StudentAttempt?) {
        guard !isTestVisible else { return }

        if DependencyInjection.shared.currentUser.role == .student {
            if resumeAttempt != nil || preloadedStudentTestId != test.id {
                testVC = nil
                preloadedStudentTestId = nil
            }

            if testVC == nil {
                testVC = DragonTestViewController(
                    test: test,
                    resumeAttempt: resumeAttempt,
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
    @objc private func dragonCaptureInfoTap() {
        let alert = UIAlertController(
            title: "Как считается дракон",
            message: "Пойманный дракон = 1, если по этому тесту в результате стоит capturedDragon = true (обычно это 320+ баллов из 400).\n\nВ профиле сумма драконов считается по всем вашим результатам.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Понятно", style: .default))
        present(alert, animated: true)
    }

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
        longPress.cancelsTouchesInView = false
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
         dragonCaptureBadge,
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
        dragonsContainer.addSubview(dragonCaptureBadge)
        dragonsContainer.addSubview(statusBadge)
        dragonsContainer.addSubview(hintView)

        dragonCaptureBadge.addTarget(self, action: #selector(dragonCaptureInfoTap), for: .touchUpInside)

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

            dragonCaptureBadge.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 12),
            dragonCaptureBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dragonCaptureBadge.heightAnchor.constraint(equalToConstant: 54),
            dragonCaptureBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 112),
            dragonCaptureBadge.widthAnchor.constraint(lessThanOrEqualToConstant: 146),

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

            titleLabel.bottomAnchor.constraint(equalTo: centerPreviewContainer.topAnchor, constant: -4),
            titleLabel.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),

            prevButton.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            prevButton.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 16),

            nextButton.centerYAnchor.constraint(equalTo: centerPreviewContainer.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -16),

            statusBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusBadge.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            statusBadge.leadingAnchor.constraint(greaterThanOrEqualTo: dragonCaptureBadge.trailingAnchor, constant: 8),
            statusBadge.trailingAnchor.constraint(lessThanOrEqualTo: statusFilterButton.leadingAnchor, constant: -8),
            statusBadge.widthAnchor.constraint(lessThanOrEqualTo: dragonsContainer.widthAnchor, multiplier: 0.60),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 188),
            statusBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 68),

            hintView.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            hintView.topAnchor.constraint(equalTo: centerPreviewContainer.bottomAnchor, constant: 20),
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
        dragonCaptureBadge.isHidden = true
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
                dragonPreview.displayEntity(
                    entity,
                    animated: container === centerPreviewContainer && isDragonScreenVisible
                )
            } else {
                dragonPreview.clear()
            }
        }
    }

    private func refreshDragonPreviews() {
        guard !items.isEmpty, currentIndex >= 0, currentIndex < items.count else { return }
        renderedPreviewKeys.removeAll(keepingCapacity: true)

        let item = items[currentIndex]
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
