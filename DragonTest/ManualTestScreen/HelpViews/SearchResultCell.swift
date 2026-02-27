//
//  SearchResultCell.swift
//  DragonTest
//
//  Created by Лазарева Александра on 26.09.2025.
//

import UIKit

// MARK: - Кастомная прозрачная ячейка поиска
final class SearchResultCell: UITableViewCell {
    static let reuseId = "SearchResultCell"

    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let addButton = UIButton(type: .system)
    private var onAdd: (() -> Void)?
    private var isAdded = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emailLabel.font = .systemFont(ofSize: 12, weight: .light)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        addButton.addAction(UIAction { [weak self] _ in
            guard let self, !self.isAdded else { return }
            self.onAdd?()
        }, for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [vStack, addButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .equalSpacing

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: User, isAdded: Bool, onAdd: @escaping () -> Void) {
        nameLabel.text = "\(user.surname) \(user.name)"
        emailLabel.text = user.email
        self.isAdded = isAdded
        self.onAdd = onAdd

        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        if isAdded {
            config.title = "Добавлен"
            config.baseForegroundColor = .white
            config.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
        } else {
            config.title = "Добавить"
            config.baseForegroundColor = .white
            config.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.35)
        }
        addButton.configuration = config
        addButton.isEnabled = !isAdded
        addButton.alpha = isAdded ? 0.8 : 1.0
    }
}
