//
//  DragonSelectViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

//
//  DragonSelectViewController.swift
//  DragonTest
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
    private var currentIndex = 0
    private var testVC: DragonTestViewController?
    private var isTestVisible = false
    
    // Hold
    private var holdTimer: Timer?
    private var holdProgress: CGFloat = 0.0
    private let holdDuration: TimeInterval = 5.0
    
    // MARK: - UI
    private let testContainer = UIView()
    private let dragonsContainer = UIView()
    private let centerPreviewContainer = UIView()
    private let leftPreviewContainer = UIView()
    private let rightPreviewContainer = UIView()
    private let titleLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let progressLabel = UILabel()
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    private let hintView = SwipeUpHintView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        
        presenter = DragonSelectPresenter(view: self)
        presenter.viewDidLoad()
        
        addGestures()
    }
    
    // MARK: - DragonSelectViewProtocol
    func updateUI(items: [CarouselItem], currentIndex: Int) {
        self.currentIndex = currentIndex
        let item = items[currentIndex]
        
        configure(container: centerPreviewContainer, item: item, scale: [0.8,0.8,0.8])
        configure(container: leftPreviewContainer, item: currentIndex > 0 ? items[currentIndex-1] : nil, scale: [0.6,0.6,0.6])
        configure(container: rightPreviewContainer, item: currentIndex < items.count-1 ? items[currentIndex+1] : nil, scale: [0.6,0.6,0.6])
        
        titleLabel.text = titleForItem(item)
        GradientBackground.attach(to: view, colors: gradientForItem(item))
        
        prevButton.isHidden = currentIndex == 0
        nextButton.isHidden = currentIndex == items.count-1
        
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
    
    func openTest(_ test: Test) {
        guard !isTestVisible else { return }
        
        let vc = DragonTestViewController(
            test: test,
            colors: test.dragonKind.gradientColors
        ) { [weak self] completed in
            self?.presenter.didFinishTest(completed: completed)
            self?.closeTest()
        }
        
        addChild(vc)
        testContainer.addSubview(vc.view)
        vc.view.frame = testContainer.bounds
        vc.didMove(toParent: self)
        testVC = vc
        
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
            testService: TestService(
                dataBase: DependencyInjection.shared.dataBase,
                currentUser: DependencyInjection.shared.currentUser
            )
        )
        addVC.delegate = self
        addVC.modalPresentationStyle = .formSheet
        present(addVC, animated: true)
    }

    
    // MARK: - Actions
    @objc private func prevTap() { presenter.didSelectPrev() }
    @objc private func nextTap() { presenter.didSelectNext() }
    @objc private func addTap() { presenter.didTapAdd() }
    
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
    
    private func startHoldTimer() {
        cancelHoldTimer()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.holdProgress += 0.1
            let percent = min(self.holdProgress / self.holdDuration, 1.0)
            self.hintView.updateProgress(percent)
            
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
        }, completion: { _ in
            self.testVC?.willMove(toParent: nil)
            self.testVC?.view.removeFromSuperview()
            self.testVC?.removeFromParent()
            self.testVC = nil
            self.isTestVisible = false
        })
    }
    
    // MARK: - UI setup helpers
    private func setupUI() {
        [testContainer, dragonsContainer,
         centerPreviewContainer, leftPreviewContainer, rightPreviewContainer,
         titleLabel, prevButton, nextButton, progressView, progressLabel, hintView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        view.addSubview(testContainer)
        view.addSubview(dragonsContainer)
        
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
            hintView.bottomAnchor.constraint(equalTo: dragonsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            hintView.widthAnchor.constraint(equalToConstant: 80),
            hintView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Стили
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        progressView.progressTintColor = .systemGreen
        
        progressLabel.font = .systemFont(ofSize: 14)
        progressLabel.textColor = .white
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
    
    private func makeArrowButton(_ title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        b.tintColor = .white
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }
}

extension DragonSelectViewController: AddTestDelegate {
    func didCreateTest(_ test: Test) {
        if let presenter = presenter as? DragonSelectPresenter {
            presenter.didCreateTest(test)
        }
    }
}
