//
//  MetricPill.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

import UIKit

// MARK: - Small metric pill (title + big value)
final class MetricPill: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 14
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        backgroundColor = UIColor.white.withAlphaComponent(0.12)

        // Title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .white.withAlphaComponent(0.95)
        titleLabel.text = title
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        // Value — авто-масштаб + без троеточий
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold) // было 26 — чуть меньше для запаса
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.allowsDefaultTighteningForTruncation = true
        valueLabel.lineBreakMode = .byClipping
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 6

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func set(value: String) { valueLabel.text = value }
}
