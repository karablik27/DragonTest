//
//  PillLabel.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class PillLabel: UIView {
    enum Style { case neutral, number, accent(UIColor), white }

    private let label = UILabel()
    private let border = CAShapeLayer()
    private let radius = ResultStyle.chipRadius
    private let container = UIView()
    private let insets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)

    init(text: String? = nil, style: Style = .neutral) {
        super.init(frame: .zero)
        backgroundColor = .clear

        label.text = text
        label.font = ResultStyle.sectionTitle
        label.textAlignment = .center
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        container.layer.cornerRadius = radius
        if #available(iOS 13.0, *) { container.layer.cornerCurve = .continuous }

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom)
        ])

        border.strokeColor = ResultStyle.pillBorder
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(border)

        apply(style)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        border.frame = bounds
    }

    func setText(_ text: String) { label.text = text }
    func setTextColor(_ color: UIColor) { label.textColor = color }
    func setBackground(_ color: UIColor) { container.backgroundColor = color }

    private func apply(_ style: Style) {
        switch style {
        case .neutral:
            container.backgroundColor = ResultStyle.pillNeutralBG
            label.textColor = .white
        case .number:
            container.backgroundColor = ResultStyle.pillNumberBG
            label.textColor = .white
        case .accent(let c):
            container.backgroundColor = c.withAlphaComponent(ResultStyle.pillAccentBGAlpha)
            label.textColor = .white
        case .white:
            container.backgroundColor = ResultStyle.whitePillBG
            label.textColor = ResultStyle.whitePillText
        }
    }
}
