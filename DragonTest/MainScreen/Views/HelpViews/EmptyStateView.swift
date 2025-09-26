//
//  EmptyStateView.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

import UIKit

final class EmptyStateView: UIView {
    
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.textColor = .lightGray
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.numberOfLines = 0
        return l
    }()
    
    init(message: String) {
        super.init(frame: .zero)
        messageLabel.text = message
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
