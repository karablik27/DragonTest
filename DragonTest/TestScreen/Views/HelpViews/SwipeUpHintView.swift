//
//  SwipeUpHintView.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//

import UIKit
import CoreHaptics

final class SwipeUpHintView: UIControl {
    private let pill = UIView()
    private let stack = UIStackView()
    private var chevrons: [UIImageView] = []
    private var isAnimating = false
    private let progressLayer = CAShapeLayer()
    private var lastStep: Int = 0
    private let label = UILabel()
    
    // MARK: - Haptics
    private var hapticEngine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        pill.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        pill.layer.cornerRadius = 28
        pill.layer.borderWidth = 5
        pill.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        pill.translatesAutoresizingMaskIntoConstraints = false
        
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pill)
        pill.addSubview(stack)
        
        NSLayoutConstraint.activate([
            pill.leadingAnchor.constraint(equalTo: leadingAnchor),
            pill.trailingAnchor.constraint(equalTo: trailingAnchor),
            pill.topAnchor.constraint(equalTo: topAnchor),
            pill.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stack.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: pill.centerYAnchor)
        ])
        
        for _ in 0..<3 {
            let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .bold)
            let iv = UIImageView(image: UIImage(systemName: "chevron.up", withConfiguration: config))
            iv.tintColor = .white
            iv.alpha = 0.3
            iv.setContentHuggingPriority(.required, for: .vertical)
            chevrons.append(iv)
            stack.addArrangedSubview(iv)
        }
        
        // текст под капсулой
        label.text = "Удерживай, чтобы начать"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.alpha = 0.9
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: pill.bottomAnchor, constant: 8)
        ])
        
        prepareHaptics()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Haptics setup
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }
    
    /// Запускаем фоновую вибрацию
    private func startContinuousVibration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        stopContinuousVibration()
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            
            let event = CHHapticEvent(eventType: .hapticContinuous,
                                      parameters: [intensity, sharpness],
                                      relativeTime: 0,
                                      duration: 5.0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try hapticEngine?.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: 0)
        } catch {
            print("Failed to start continuous vibration: \(error)")
        }
    }
    
    /// Останавливаем фон
    private func stopContinuousVibration() {
        do {
            try continuousPlayer?.stop(atTime: 0)
            continuousPlayer = nil
        } catch {
            print("Failed to stop continuous vibration: \(error)")
        }
    }
    
    /// Короткий пульс (на шаге)
    private func pulse(intensity: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
            
            let event = CHHapticEvent(eventType: .hapticTransient,
                                      parameters: [intensityParam, sharpnessParam],
                                      relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Pulse haptic error: \(error)")
        }
    }
    
    // MARK: - Animations
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        animateLoop()
    }
    
    func stopAnimating() {
        isAnimating = false
        layer.removeAllAnimations()
        chevrons.forEach {
            $0.layer.removeAllAnimations()
            $0.alpha = 0.3
            $0.transform = .identity
        }
        lastStep = 0
        stopContinuousVibration()
    }
    
    private func animateLoop() {
        guard isAnimating else { return }
        let duration: TimeInterval = 0.9
        for (i, iv) in chevrons.enumerated() {
            UIView.animate(withDuration: duration,
                           delay: Double(i) * 0.15,
                           options: [.repeat, .autoreverse, .allowUserInteraction]) {
                iv.alpha = 1.0
                iv.transform = CGAffineTransform(translationX: 0, y: -8)
            }
        }
    }
    
    /// Обновление прогресса (0…1)
    func updateProgress(_ percent: CGFloat) {
        pill.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.6 + 0.4 * percent).cgColor
        
        for (i, iv) in chevrons.enumerated() {
            iv.tintColor = percent >= CGFloat(i+1)/3.0 ? .systemGreen : .white
        }
        
        // запускаем фон при первом удержании
        if percent > 0 && continuousPlayer == nil {
            startContinuousVibration()
        }
        
        // обновляем силу фоновой вибрации
        if let player = continuousPlayer {
            let param = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                 value: Float(percent), // 0...1
                                                 relativeTime: 0)
            try? player.sendParameters([param], atTime: 0)
        }
        
        let step = Int(percent * 3)
        if step != lastStep {
            lastStep = step
            if step > 0 { pulse(intensity: Float(percent)) }
        }
        
        label.isHidden = percent != 0
    }
    
    func resetProgress() {
        pill.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        chevrons.forEach { $0.tintColor = .white }
        lastStep = 0
        label.isHidden = false
        stopContinuousVibration()
    }
}
