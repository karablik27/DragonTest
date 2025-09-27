//
//  ScoreBadge.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

import UIKit

final class ScoreBadge: UIView {
    private let gradient = CAGradientLayer()
    private let label = UILabel()
    private let border = CAShapeLayer()
    private let radius: CGFloat = 12
    private let accent: UIColor

    init(accent: UIColor) {
        self.accent = accent
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }

        gradient.colors = [
            accent.withAlphaComponent(0.45).cgColor,
            accent.withAlphaComponent(0.25).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = radius
        layer.insertSublayer(gradient, at: 0)

        border.strokeColor = UIColor.white.withAlphaComponent(0.25).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)

        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.text = "—"

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])

        // мягкое свечение в цвет акцента
        layer.shadowColor = accent.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }

    func setValue(_ text: String) { label.text = text }
}
