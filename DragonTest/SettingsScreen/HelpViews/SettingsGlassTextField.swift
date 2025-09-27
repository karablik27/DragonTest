//
//  SettingsGlassTextField.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit

final class SettingsGlassTextField: UIView {
    let textField = UITextField()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let border = CAShapeLayer()
    private let radius: CGFloat = 12

    var text: String? { get { textField.text } set { textField.text = newValue } }

    init(placeholder: String, isSecure: Bool = false, keyboard: UIKeyboardType = .default) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous 
        clipsToBounds = true

        blur.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        textField.translatesAutoresizingMaskIntoConstraints = false
                textField.backgroundColor = .clear
                textField.borderStyle = .none
                textField.placeholder = placeholder
                textField.isSecureTextEntry = isSecure
                textField.keyboardType = keyboard
                textField.clearButtonMode = .whileEditing
                textField.autocapitalizationType = .none
                textField.font = .systemFont(ofSize: 14)
        
        addSubview(textField)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        border.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }
}
