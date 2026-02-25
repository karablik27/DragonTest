//
//  CalendarDayCell.swift
//  DragonTest
//
//  Created by Крючков Сергей on 27.09.2025.
//

import UIKit
import Foundation

class CalendarDayCell: UICollectionViewCell {
    let dayLabel = UILabel()
    private let activityIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.layer.cornerRadius = 10
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1

        dayLabel.textAlignment = .center
        dayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.layer.cornerRadius = 2.5
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(dayLabel)
        contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -2),

            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            activityIndicator.widthAnchor.constraint(equalToConstant: 5),
            activityIndicator.heightAnchor.constraint(equalToConstant: 5)
        ])
    }

    func configure(hasActivity: Bool, isToday: Bool) {
        activityIndicator.isHidden = !hasActivity

        if isToday {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
            dayLabel.textColor = .white
            dayLabel.font = .systemFont(ofSize: 14, weight: .bold)
            contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
            activityIndicator.backgroundColor = .white
        } else if hasActivity {
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.20)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            contentView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
            activityIndicator.backgroundColor = UIColor.systemGreen
        } else {
            contentView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.58)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
            contentView.layer.borderColor = UIColor.separator.withAlphaComponent(0.55).cgColor
            activityIndicator.backgroundColor = .clear
        }
    }
}
