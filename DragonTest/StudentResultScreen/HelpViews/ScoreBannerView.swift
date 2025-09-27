//
//  ScoreBannerView.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

//  ScoreBannerView.swift
import UIKit

final class ScoreBannerView: UIView {
    private let card = ResultGlassCard(radius: 20)

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = UIColor.white.withAlphaComponent(0.9)
        l.textAlignment = .center
        l.text = "result.preliminary_score_ai".localized
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 44, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.text = "—"
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        l.textAlignment = .center
        l.text = "result.awaiting_teacher_review".localized
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        let v = UIStackView(arrangedSubviews: [titleLabel, valueLabel, subtitleLabel])
        v.axis = .vertical
        v.spacing = 6
        card.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor),
            card.leadingAnchor.constraint(equalTo: leadingAnchor),
            card.trailingAnchor.constraint(equalTo: trailingAnchor),
            card.bottomAnchor.constraint(equalTo: bottomAnchor),

            v.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 96)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Обновляем состояние баннера.
    /// - Parameters:
    ///   - aiScore: балл ИИ (если ещё нет проверки учителем)
    ///   - teacherScore: итоговый балл (если есть)
    func configure(aiScore: Int?, teacherScore: Int?) {
        if let t = teacherScore {
            // Итог
            titleLabel.text = "result.final_grade".localized
            valueLabel.text = "\(t)"
            subtitleLabel.text = "result.checked_by_teacher".localized
        } else if let ai = aiScore {
            // Промежуточно (ИИ)
            titleLabel.text = "result.preliminary_score_ai".localized
            valueLabel.text = "\(ai)"
            subtitleLabel.text = "result.awaiting_teacher_review".localized
        } else {
            titleLabel.text = "common.grade".localized
            valueLabel.text = "—"
            subtitleLabel.text = "result.no_data".localized
        }
    }
}
