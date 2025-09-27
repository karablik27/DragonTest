//
//  ScoreSummaryView.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

//  ScoreSummaryView.swift
//  DragonTest

import UIKit

final class ScoreSummaryView: UIView {
    private let card = ResultGlassCard()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white.withAlphaComponent(0.95)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        valueLabel.font = .systemFont(ofSize: 36, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.85)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 6

        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            valueLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Конфигурируем данные карточки
    func configure(value: Int?, isFinal: Bool) {
        if isFinal {
            titleLabel.text = "result.final_score".localized
            subtitleLabel.text = "result.checked_by_teacher".localized
        } else {
            titleLabel.text = "result.preliminary_score_ai".localized
            subtitleLabel.text = "result.awaiting_teacher_review".localized
        }
        valueLabel.text = value.map(String.init) ?? "—"
    }
}
