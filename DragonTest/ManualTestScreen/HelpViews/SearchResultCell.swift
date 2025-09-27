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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        nameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.font = .systemFont(ofSize: 12, weight: .light)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        addButton.setTitle("Добавить", for: .normal)
        addButton.tintColor = .systemBlue
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd?() }, for: .touchUpInside)

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

    func configure(with user: User, onAdd: @escaping () -> Void) {
        nameLabel.text = "\(user.name) \(user.surname)"
        emailLabel.text = user.email
        self.onAdd = onAdd
    }
}
