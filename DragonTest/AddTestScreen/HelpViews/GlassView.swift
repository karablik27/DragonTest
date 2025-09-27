//
//  GlassView.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class GlassView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let borderLayer = CAShapeLayer()
    private let corner: CGFloat

    init(radius: CGFloat = 20) {
        self.corner = radius
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = radius
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
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: corner)
        borderLayer.path = path.cgPath
        borderLayer.frame = bounds
    }
}
