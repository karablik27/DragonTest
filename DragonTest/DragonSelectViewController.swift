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
    case test(DragonTest)
}

extension CarouselItem {
    var isTest: Bool {
        if case .test = self { return true }
        return false
    }
}

final class DragonSelectViewController: UIViewController {
    
    // MARK: - Data
    private var items: [CarouselItem] = [.addButton]
    private var currentIndex = 0 {
        didSet { updateUI() }
    }
    
    private var isTestVisible = false
    private var testVC: DragonTestViewController?
    
    // удержание
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
        
        // testContainer под драконом
        testContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testContainer)
        NSLayoutConstraint.activate([
            testContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            testContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            testContainer.topAnchor.constraint(equalTo: view.topAnchor),
            testContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // dragonsContainer поверх
        dragonsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dragonsContainer)
        NSLayoutConstraint.activate([
            dragonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dragonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dragonsContainer.topAnchor.constraint(equalTo: view.topAnchor),
            dragonsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        [leftPreviewContainer, centerPreviewContainer, rightPreviewContainer,
         titleLabel, prevButton, nextButton, progressView, progressLabel, hintView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            dragonsContainer.addSubview($0)
        }
        
        setupConstraints()
        addGestures()
        
        Task { @MainActor in
            await DragonCache.shared.preload()
            updateUI()
        }
    }
    
    // MARK: - Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
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
        
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.2)
        progressView.progressTintColor = .systemGreen
        
        progressLabel.font = .systemFont(ofSize: 14)
        progressLabel.textColor = .white
    }
    
    private func addGestures() {
        let swipeL = UISwipeGestureRecognizer(target: self, action: #selector(nextTap))
        swipeL.direction = .left
        dragonsContainer.addGestureRecognizer(swipeL)
        
        let swipeR = UISwipeGestureRecognizer(target: self, action: #selector(prevTap))
        swipeR.direction = .right
        dragonsContainer.addGestureRecognizer(swipeR)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        dragonsContainer.addGestureRecognizer(longPress)
    }
    
    private func makeArrowButton(_ title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        b.tintColor = .white
        b.addTarget(nil, action: action, for: .touchUpInside)
        return b
    }
    
    // MARK: - Long press hold
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard items[currentIndex].isTest else { return }
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
                self.openTest()
            }
        }
    }
    
    private func cancelHoldTimer() {
        holdTimer?.invalidate()
        holdTimer = nil
        hintView.resetProgress()
        holdProgress = 0
    }
    
    // MARK: - UI Update
    private func updateUI() {
        let centerItem = items[currentIndex]
        let leftItem = currentIndex > 0 ? items[currentIndex-1] : nil
        let rightItem = currentIndex < items.count-1 ? items[currentIndex+1] : nil
        
        configure(container: centerPreviewContainer, item: centerItem, scale: [0.8,0.8,0.8])
        configure(container: leftPreviewContainer, item: leftItem, scale: [0.6,0.6,0.6])
        configure(container: rightPreviewContainer, item: rightItem, scale: [0.6,0.6,0.6])
        
        titleLabel.text = titleForItem(centerItem)
        
        let colors = gradientForItem(centerItem)
        GradientBackground.attach(to: view, colors: colors)
        
        prevButton.isHidden = currentIndex == 0
        nextButton.isHidden = currentIndex == items.count-1
        
        updateProgress(for: centerItem)
        
        if centerItem.isTest {
            hintView.isHidden = false
        } else {
            hintView.isHidden = true
        }
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
            addView.button.addTarget(self, action: #selector(addDragon), for: .touchUpInside)
            
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
            if let entity = DragonCache.shared.clone(for: test.dragon, scale: scale) {
                preview.displayEntity(entity)
            }
        }
    }
    
    private func gradientForItem(_ item: CarouselItem) -> [CGColor] {
        switch item {
        case .addButton:
            return [UIColor.darkGray.cgColor, UIColor.black.cgColor]
        case .test(let test):
            return test.dragon.gradientColors
        }
    }
    
    private func titleForItem(_ item: CarouselItem) -> String {
        switch item {
        case .addButton: return "Добавить дракона"
        case .test(let test): return test.dragon.title
        }
    }
    
    private func updateProgress(for item: CarouselItem) {
        switch item {
        case .addButton:
            progressView.isHidden = true
            progressLabel.isHidden = true
        case .test(let test):
            progressView.isHidden = false
            progressLabel.isHidden = false
            let progress = Float(test.completed) / Float(max(test.totalQuestions, 1))
            progressView.setProgress(progress, animated: true)
            progressLabel.text = "Пройдено \(test.completed) из \(test.totalQuestions)"
        }
    }
    
    // MARK: - Actions
    @objc private func prevTap() {
        guard currentIndex > 0 else { return }
        animateCarousel(direction: -1)
    }
    
    @objc private func nextTap() {
        guard currentIndex < items.count-1 else { return }
        animateCarousel(direction: 1)
    }
    
    @objc private func addDragon() {
        let test = MockTestService.shared.randomTest()
        items.append(.test(test))
        currentIndex = items.count - 1
    }
    
    @objc private func openTest() {
        guard !isTestVisible, case let .test(test) = items[currentIndex] else { return }
        
        let colors = test.dragon.gradientColors
        let vc = DragonTestViewController(test: test, colors: colors) { [weak self] completed in
            guard let self else { return }
            if case .test(var t) = self.items[self.currentIndex] {
                t.completed = completed
                self.items[self.currentIndex] = .test(t)
                self.updateUI()
            }
            self.closeTest()
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
    
    private func animateCarousel(direction: Int) {
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
            self.currentIndex += direction
            self.updateUI()
            
            self.centerPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? shiftCenter : -shiftCenter, y: 0
            ).scaledBy(x: 0.9, y: 0.9)
            self.centerPreviewContainer.alpha = 0
            
            self.leftPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? -shiftSide : shiftSide, y: 0
            )
            self.rightPreviewContainer.transform = CGAffineTransform(
                translationX: direction == 1 ? -shiftSide : shiftSide, y: 0
            )
            
            UIView.animate(withDuration: dur) {
                self.centerPreviewContainer.transform = .identity
                self.centerPreviewContainer.alpha = 1
                self.leftPreviewContainer.transform = .identity
                self.rightPreviewContainer.transform = .identity
                self.leftPreviewContainer.alpha = 0.5
                self.rightPreviewContainer.alpha = 0.5
            }
        })
    }
}
