//
//  ResultGlassCard.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class ResultGlassCard: UIView {
    private let blur  = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
    private let border = CAShapeLayer()
    private let highlight = CAGradientLayer()
    private let radius: CGFloat

    init(radius: CGFloat = ResultStyle.cardRadius) {
        self.radius = radius
        super.init(frame: .zero)

        backgroundColor = ResultStyle.cardFill
        isOpaque = false
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // едва заметный глянец сверху — даёт «стекло»
        highlight.colors = [UIColor.white.withAlphaComponent(0.10).cgColor, UIColor.clear.cgColor]
        highlight.startPoint = CGPoint(x: 0.5, y: 0.0)
        highlight.endPoint   = CGPoint(x: 0.5, y: 1.0)
        highlight.cornerRadius = radius
        layer.addSublayer(highlight)

        border.strokeColor = ResultStyle.stroke
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
        highlight.frame = bounds
    }
}
