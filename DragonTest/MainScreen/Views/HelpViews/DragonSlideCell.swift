//
//  DragonSlideCell.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//


import UIKit
import RealityKit

final class DragonSlideCell: UICollectionViewCell {
    static let reuseId = "DragonSlideCell"
    
    private let preview = DragonPreviewView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(preview)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        
        [preview, titleLabel, infoLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        
        infoLabel.font = .systemFont(ofSize: 16)
        infoLabel.textAlignment = .center
        infoLabel.textColor = .white
        infoLabel.numberOfLines = 0
        
        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -40),
            preview.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.75),
            preview.heightAnchor.constraint(equalTo: preview.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: preview.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            infoLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with test: Test) {
        GradientBackground.attach(to: contentView, colors: test.dragonKind.gradientColors)
        
        if let entity = DependencyInjection.shared.dragonCache.clone(for: test.dragonKind, scale: [0.8,0.8,0.8]) {
            preview.displayEntity(entity)
        }
        
        titleLabel.text = test.dragonKind.title
        
        let total = test.questions.count
        
        infoLabel.text = "Вопросов: \(total)"
    }

}
