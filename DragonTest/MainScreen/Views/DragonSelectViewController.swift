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

        // Card as background container
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.topAnchor.constraint(equalTo: topAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Content
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
        if lower.contains("прошли:") {
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

    // Hold
    private var holdTimer: Timer?
    private var holdProgress: CGFloat = 0.0
    private let holdDuration: TimeInterval = 5.0

    // MARK: - UI
    private let testContainer = UIView()
    private let dragonsContainer = UIView()

    private let gradientHost = UIView()
    private let bgLayer = CAGradientLayer()

    private let centerPreviewContainer = UIView()
    private let leftPreviewContainer = UIView()
    private let rightPreviewContainer = UIView()
    private let titleLabel = UILabel()
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    private let hintView = SwipeUpHintView()
    private var currentColors: [CGColor] = [UIColor.darkGray.cgColor, UIColor.black.cgColor]

    private let emptyStateView = EmptyStateView(message: "Нет доступных тестов")

    // NEW: стеклянная плашка статуса
    private let statusBadge = StatusBadgeView(radius: 18)

    // (Старые прогресс-элементы больше не используются, оставлены только чтобы не ломать код)
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
        self.items = items
        self.currentIndex = currentIndex

        emptyStateView.isHidden = true
        dragonsContainer.isHidden = false

        let item = items[currentIndex]

        // фон
        applyGradient(for: item, animated: false)

        // драконы
        configure(container: centerPreviewContainer, item: item, scale: [0.8, 0.8, 0.8])
        configure(container: leftPreviewContainer,
                  item: currentIndex > 0 ? items[currentIndex - 1] : nil,
                  scale: [0.6, 0.6, 0.6])
        configure(container: rightPreviewContainer,
                  item: currentIndex < items.count - 1 ? items[currentIndex + 1] : nil,
                  scale: [0.6, 0.6, 0.6])

        // заголовки и стрелки
        titleLabel.text = titleForItem(item)
        prevButton.isHidden = currentIndex == 0
        nextButton.isHidden = currentIndex == items.count - 1

        // скрываем старый прогресс и показываем статусный бейдж
        progressView.isHidden = true
        progressLabel.isHidden = true
        statusBadge.isHidden = false
        hintView.isHidden = !(item.isTest)

        // запрос статуса для бейджа
        presenter.requestStatus(for: currentIndex)
    }

    func updateStatus(_ text: String) {
        UIView.transition(with: statusBadge, duration: 0.2, options: .transitionCrossDissolve) {
            self.statusBadge.update(text: text)
        }
    }

    func showEmptyState() {
        dragonsContainer.isHidden = true
        emptyStateView.isHidden = false
        statusBadge.isHidden = true
    }

    func openTest(_ test: Test) {
        guard !isTestVisible else { return }

        if DependencyInjection.shared.currentUser.role == .student {
            if testVC == nil {
                testVC = DragonTestViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                ) { [weak self] completed in
                    self?.presenter.didFinishTest(completed: completed)
                    self?.closeTest()
                }
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
            if teacherVC == nil {
                let vc = TeacherReviewViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                )
                vc.onClose = { [weak self] in self?.closeTest() }
                teacherVC = vc
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

    // MARK: - Общая анимация открытия
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

            // PRELOAD Student
            if percent >= 0.3, self.testVC == nil,
               case let .test(test) = self.items[self.currentIndex] {
                self.testVC = DragonTestViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                ) { [weak self] completed in
                    self?.presenter.didFinishTest(completed: completed)
                    self?.closeTest()
                }
                _ = self.testVC?.view
                self.testVC?.view.layoutIfNeeded()
            }
            // PRELOAD Teacher
            if DependencyInjection.shared.currentUser.role == .teacher,
               percent >= 0.30,
               self.teacherVC == nil,
               case let .test(test) = self.items[self.currentIndex] {

                let vc = TeacherReviewViewController(
                    test: test,
                    colors: test.dragonKind.gradientColors
                )
                vc.onClose = { [weak self] in self?.closeTest() }
                self.teacherVC = vc
                _ = vc.view
                vc.view.layoutIfNeeded()
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
            self.resultVC = nil
            self.isTestVisible = false
            self.testContainer.alpha = 1
            self.updateUI(items: self.items, currentIndex: self.currentIndex)
        })
    }

    // MARK: - UI
    private func setupUI() {
        [testContainer, dragonsContainer,
         gradientHost,
         centerPreviewContainer, leftPreviewContainer, rightPreviewContainer,
         titleLabel, prevButton, nextButton,
         hintView, emptyStateView,
         statusBadge,
         progressView, progressLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(testContainer)
        view.addSubview(dragonsContainer)
        view.addSubview(emptyStateView)

        // фон
        dragonsContainer.addSubview(gradientHost)
        NSLayoutConstraint.activate([
            gradientHost.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor),
            gradientHost.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor),
            gradientHost.topAnchor.constraint(equalTo: dragonsContainer.topAnchor),
            gradientHost.bottomAnchor.constraint(equalTo: dragonsContainer.bottomAnchor)
        ])
        bgLayer.startPoint = CGPoint(x: 0, y: 0)
        bgLayer.endPoint   = CGPoint(x: 1, y: 1)
        gradientHost.layer.addSublayer(bgLayer)
        dragonsContainer.sendSubviewToBack(gradientHost)

        // контент
        dragonsContainer.addSubview(centerPreviewContainer)
        dragonsContainer.addSubview(leftPreviewContainer)
        dragonsContainer.addSubview(rightPreviewContainer)
        dragonsContainer.addSubview(titleLabel)
        dragonsContainer.addSubview(prevButton)
        dragonsContainer.addSubview(nextButton)

        // статусная стеклянная плашка
        dragonsContainer.addSubview(statusBadge)

        // хинт под статусом
        dragonsContainer.addSubview(hintView)

        // пустой стейт и базовая раскладка
        NSLayoutConstraint.activate([
            testContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            testContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            testContainer.topAnchor.constraint(equalTo: view.topAnchor),
            testContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dragonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dragonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dragonsContainer.topAnchor.constraint(equalTo: view.topAnchor),
            dragonsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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

            // статус под драконом
            statusBadge.topAnchor.constraint(equalTo: centerPreviewContainer.bottomAnchor, constant: 16),
            statusBadge.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 40),
            statusBadge.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -40),

            // хинт под статусом
            hintView.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            hintView.topAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: 14),
            hintView.widthAnchor.constraint(equalToConstant: 80),
            hintView.heightAnchor.constraint(equalToConstant: 120),

            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // стили
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white

        prevButton.isHidden = true
        nextButton.isHidden = true
        hintView.isHidden = true
        emptyStateView.isHidden = true

        // старые виджеты прогресса полностью прячем
        progressView.isHidden = true
        progressLabel.isHidden = true

        testContainer.backgroundColor = .clear
    }

    private func configure(container: UIView, item: CarouselItem?, scale: SIMD3<Float>) {
        container.subviews.forEach { $0.removeFromSuperview() }
        guard let item else { return }

        switch item {
        case .addButton:
            let addView = AddButtonPreviewView()
            addView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(addView)
            NSLayoutConstraint.activate([
                addView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                addView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                addView.topAnchor.constraint(equalTo: container.topAnchor),
                addView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            addView.button.addTarget(self, action: #selector(addTap), for: .touchUpInside)

        case .test(let test):
            let preview = DragonPreviewView()
            preview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(preview)
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                preview.topAnchor.constraint(equalTo: container.topAnchor),
                preview.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            if let entity = DependencyInjection.shared.dragonCache.clone(for: test.dragonKind, scale: scale) {
                preview.displayEntity(entity)
            }
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
        if let presenter = presenter as? DragonSelectPresenter {
            presenter.didCreateTest(newTest)
        }
    }

    func didCreateTest(_ test: Test) {
        if let presenter = presenter as? DragonSelectPresenter {
            presenter.didCreateTest(test)
        }
    }
}
