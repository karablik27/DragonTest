//
//  GlassTextField.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class GlassTextField: UIView {
    let textField = UITextField()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let borderLayer = CAShapeLayer()
    private let corner: CGFloat = 12

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    init(placeholder: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = corner
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.placeholder = placeholder
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        addSubview(textField)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: corner).cgPath
        borderLayer.frame = bounds
    }
}
