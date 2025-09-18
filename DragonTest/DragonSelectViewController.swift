//
//  DragonSelectViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit
import RealityKit

final class DragonSelectViewController: UIViewController {
    
    // MARK: - Data
    private let kinds = DragonKind.allCases
    private var currentIndex = 0 {
        didSet { updateUI() }
    }
    
    // MARK: - UI
    private let centerPreview = DragonPreviewView()
    private let leftPreview = DragonPreviewView()
    private let rightPreview = DragonPreviewView()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textAlignment = .center
        l.textColor = .white
        return l
    }()
    
    private lazy var prevButton = makeArrowButton("◀︎", action: #selector(prevTap))
    private lazy var nextButton = makeArrowButton("▶︎", action: #selector(nextTap))
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        GradientBackground.attach(to: view, colors: kinds[currentIndex].gradientColors)
        
        [leftPreview, centerPreview, rightPreview,
         titleLabel, prevButton, nextButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        setupConstraints()
        addGestures()
        
        Task { @MainActor in
            await DragonCache.shared.preload()
            displayPreviews()
        }
        
        updateUI()
    }
    
    // MARK: - Helpers
    private func idx(_ offset: Int) -> Int {
        (currentIndex + offset + kinds.count) % kinds.count
    }
    
    private func displayPreviews() {
        centerPreview.display(kind: kinds[idx(0)], scale: [0.8,0.8,0.8])
        leftPreview.display(kind: kinds[idx(-1)], scale: [0.6,0.6,0.6])
        rightPreview.display(kind: kinds[idx(1)], scale: [0.6,0.6,0.6])
    }
    
    private func updateUI() {
        GradientBackground.attach(to: view, colors: kinds[currentIndex].gradientColors)
        titleLabel.text = kinds[currentIndex].title
        displayPreviews()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            centerPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerPreview.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            centerPreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.80),
            centerPreview.heightAnchor.constraint(equalTo: centerPreview.widthAnchor),
            
            leftPreview.centerYAnchor.constraint(equalTo: centerPreview.centerYAnchor),
            leftPreview.trailingAnchor.constraint(equalTo: centerPreview.leadingAnchor, constant: -20),
            leftPreview.widthAnchor.constraint(equalTo: centerPreview.widthAnchor, multiplier: 0.55),
            leftPreview.heightAnchor.constraint(equalTo: leftPreview.widthAnchor),
            
            rightPreview.centerYAnchor.constraint(equalTo: centerPreview.centerYAnchor),
            rightPreview.leadingAnchor.constraint(equalTo: centerPreview.trailingAnchor, constant: 20),
            rightPreview.widthAnchor.constraint(equalTo: centerPreview.widthAnchor, multiplier: 0.55),
            rightPreview.heightAnchor.constraint(equalTo: rightPreview.widthAnchor),
            
            titleLabel.bottomAnchor.constraint(equalTo: centerPreview.topAnchor, constant: -16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            prevButton.centerYAnchor.constraint(equalTo: centerPreview.centerYAnchor),
            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            nextButton.centerYAnchor.constraint(equalTo: centerPreview.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            
        ])
    }
    
    private func addGestures() {
        let swipeL = UISwipeGestureRecognizer(target: self, action: #selector(nextTap))
        swipeL.direction = .left
        view.addGestureRecognizer(swipeL)
        
        let swipeR = UISwipeGestureRecognizer(target: self, action: #selector(prevTap))
        swipeR.direction = .right
        view.addGestureRecognizer(swipeR)
    }
    
    private func makeArrowButton(_ title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
        b.tintColor = .white
        b.addTarget(nil, action: action, for: .touchUpInside)
        return b
    }
    
    // MARK: - Actions
    @objc private func prevTap() { animateCarousel(direction: -1) }
    @objc private func nextTap() { animateCarousel(direction: 1) }
    
    
    private func animateCarousel(direction: Int) {
        let width = view.bounds.width
        let shiftCenter = width * 0.20
        let shiftSide = width * 0.10
        let dur: TimeInterval = 0.28
        
        UIView.animate(withDuration: dur, animations: {
            self.centerPreview.transform = CGAffineTransform(translationX: direction == 1 ? -shiftCenter : shiftCenter, y: 0).scaledBy(x: 0.9, y: 0.9)
            self.centerPreview.alpha = 0
            self.leftPreview.transform = CGAffineTransform(translationX: direction == 1 ? -shiftSide : shiftSide, y: 0).scaledBy(x: 0.95, y: 0.95)
            self.rightPreview.transform = CGAffineTransform(translationX: direction == 1 ? -shiftSide : shiftSide, y: 0).scaledBy(x: 0.95, y: 0.95)
            self.leftPreview.alpha = 0.35
            self.rightPreview.alpha = 0.35
        }, completion: { _ in
            self.currentIndex = self.idx(direction)
            self.displayPreviews()
            
            self.centerPreview.transform = CGAffineTransform(translationX: direction == 1 ? shiftCenter : -shiftCenter, y: 0).scaledBy(x: 0.9, y: 0.9)
            self.centerPreview.alpha = 0
            self.leftPreview.transform = CGAffineTransform(translationX: direction == 1 ? -shiftSide : shiftSide, y: 0)
            self.rightPreview.transform = CGAffineTransform(translationX: direction == 1 ? -shiftSide : shiftSide, y: 0)
            
            UIView.animate(withDuration: dur) {
                self.centerPreview.transform = .identity
                self.centerPreview.alpha = 1
                self.leftPreview.transform = .identity
                self.rightPreview.transform = .identity
                self.leftPreview.alpha = 0.5
                self.rightPreview.alpha = 0.5
            }
        })
    }
}
