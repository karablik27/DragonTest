//
//  DragonSelectViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit
import RealityKit

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
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    private let hintView = SwipeUpHintView()
    private var currentColors: [CGColor] = [UIColor.darkGray.cgColor, UIColor.black.cgColor]

    private let emptyStateView = EmptyStateView(message: "Нет доступных тестов")

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
    
    func currentGradientColors() -> [CGColor] {
        return currentColors
    }

    // MARK: - DragonSelectViewProtocol
    func updateUI(items: [CarouselItem], currentIndex: Int) {
        self.items = items
        self.currentIndex = currentIndex

        emptyStateView.isHidden = true
        dragonsContainer.isHidden = false

        let item = items[currentIndex]

        // фон ставим сразу, без внешних утилит
        applyGradient(for: item, animated: false)

        // драконы
        configure(container: centerPreviewContainer, item: item, scale: [0.8, 0.8, 0.8])
        configure(container: leftPreviewContainer,
                  item: currentIndex > 0 ? items[currentIndex - 1] : nil,
                  scale: [0.6, 0.6, 0.6])
        configure(container: rightPreviewContainer,
                  item: currentIndex < items.count - 1 ? items[currentIndex + 1] : nil,
                  scale: [0.6, 0.6, 0.6])

        // заголовки и кнопки
        titleLabel.text = titleForItem(item)
        prevButton.isHidden = currentIndex == 0
        nextButton.isHidden = currentIndex == items.count - 1

        if case .test = item {
            progressView.isHidden = false
            progressLabel.isHidden = false
            progressView.setProgress(0, animated: false)
            progressLabel.text = "Пройдено 0 из 40"
            hintView.isHidden = false
        } else {
            progressView.isHidden = true
            progressLabel.isHidden = true
            hintView.isHidden = true
        }
    }

    func showEmptyState() {
        dragonsContainer.isHidden = true
        emptyStateView.isHidden = false
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
                
                // если хотим, чтобы данные начали грузиться ещё до показа
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

    // MARK: - Открытие результата
    func openResult(_ vc: StudentResultViewController) {
        guard !isTestVisible else { return }

        resultVC = vc
        vc.onClose = { [weak self] in
            self?.closeTest()
        }

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

        // плавно меняем фон под новый элемент
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
        let addVC = AddTestViewController(
            testService: DependencyInjection.shared.testService
        )
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

            // preload
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
            
            // --- PRELOAD: TeacherReview (для учителя) ---
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

                // тёплый старт UI + запуск загрузок презентера
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
            // Возвращаем карусель вместе с фоном
            self.dragonsContainer.transform = .identity
            // Гасим перекрывающий testContainer, чтобы не было «чёрной прослойки»
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
            self.testContainer.alpha = 1 // подготовим к следующему открытию
            self.updateUI(items: self.items, currentIndex: self.currentIndex)
        })
    }

    // MARK: - UI setup helpers
    private func setupUI() {
        [testContainer, dragonsContainer,
         gradientHost,
         centerPreviewContainer, leftPreviewContainer, rightPreviewContainer,
         titleLabel, prevButton, nextButton, progressView, progressLabel, hintView, emptyStateView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(testContainer)
        view.addSubview(dragonsContainer)
        view.addSubview(emptyStateView)

        // Градиент внутри dragonsContainer
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

        dragonsContainer.addSubview(centerPreviewContainer)
        dragonsContainer.addSubview(leftPreviewContainer)
        dragonsContainer.addSubview(rightPreviewContainer)
        dragonsContainer.addSubview(titleLabel)
        dragonsContainer.addSubview(prevButton)
        dragonsContainer.addSubview(nextButton)
        dragonsContainer.addSubview(progressView)
        dragonsContainer.addSubview(progressLabel)
        dragonsContainer.addSubview(hintView)

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

            progressView.topAnchor.constraint(equalTo: centerPreviewContainer.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: dragonsContainer.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: dragonsContainer.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),

            hintView.centerXAnchor.constraint(equalTo: dragonsContainer.centerXAnchor),
            hintView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            hintView.widthAnchor.constraint(equalToConstant: 80),
            hintView.heightAnchor.constraint(equalToConstant: 120),

            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Стили
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white

        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        progressView.progressTintColor = .systemGreen

        progressLabel.font = .systemFont(ofSize: 14)
        progressLabel.textColor = .white

        prevButton.isHidden = true
        nextButton.isHidden = true
        progressView.isHidden = true
        progressLabel.isHidden = true
        hintView.isHidden = true
        emptyStateView.isHidden = true

        // чтобы чёрный фон не просвечивал при возвращении
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

