//
//  FieldGlass.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class FieldGlass: UIView {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let border = CAShapeLayer()
    private let radius: CGFloat

    init(radius: CGFloat = ResultStyle.answerRadius) {
        self.radius = radius
        super.init(frame: .zero)
        isOpaque = false
        backgroundColor = UIColor.white.withAlphaComponent(0.06)
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }

        addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        border.strokeColor = UIColor.white.withAlphaComponent(0.20).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }
}
