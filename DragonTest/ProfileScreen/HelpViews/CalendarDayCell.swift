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
        layer.cornerRadius = 8
        
        dayLabel.textAlignment = .center
        dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        activityIndicator.backgroundColor = .systemBlue
        activityIndicator.layer.cornerRadius = 3
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(dayLabel)
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            activityIndicator.widthAnchor.constraint(equalToConstant: 6),
            activityIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func configure(hasActivity: Bool, isToday: Bool) {
        activityIndicator.isHidden = !hasActivity
        
        if isToday {
            // Сегодняшний день - яркий синий фон
            backgroundColor = UIColor.systemBlue
            dayLabel.textColor = .white
            dayLabel.font = .systemFont(ofSize: 14, weight: .bold)
            layer.borderWidth = 0
        } else if hasActivity {
            // День с активностью - светло-зеленый фон
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            layer.borderWidth = 1
            layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            // Обычный день - легкий белый фон с границей
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.separator.cgColor
        }
        
        if hasActivity {
            if isToday {
                activityIndicator.backgroundColor = .white
            } else {
                activityIndicator.backgroundColor = .systemGreen
            }
        }
    }
}
