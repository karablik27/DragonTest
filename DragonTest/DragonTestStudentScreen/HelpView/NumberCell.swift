//
//  NumberCell.swift
//  DragonTest
//
//  Created by Карабельников Степан 26.09.2025.
//

import UIKit

final class NumberCell: UICollectionViewCell {
    
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let border = CAShapeLayer()
    private let label = UILabel()
    private let radius: CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = radius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        
        blur.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: contentView.topAnchor),
            blur.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        blur.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: blur.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: blur.contentView.centerYAnchor)
        ])
        
        border.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 1.0 / UIScreen.main.scale
        contentView.layer.addSublayer(border)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        border.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: radius).cgPath
        border.frame = contentView.bounds
    }
    
    func configure(number: Int, isCurrent: Bool, isAnswered: Bool) {
        label.text = "\(number)"
        label.textColor = .black

        if isCurrent {
            blur.effect = nil
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        } else if isAnswered {
            blur.effect = nil
            contentView.backgroundColor = UIColor.white
        } else {
            blur.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            contentView.backgroundColor = .clear
        }
    }


}

