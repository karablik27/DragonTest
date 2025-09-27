//
//  TeacherStudentCell.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class TeacherStudentCell: UITableViewCell {
    enum Status { case teacherDone, llmDoneWaitTeacher, llmPending, notPassed }

    let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusGlass = FieldGlass(radius: 10)
    private let statusLabel = InsetLabel()
    private let card = ResultGlassCard(radius: 22)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Avatar
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate)
        avatarView.tintColor = .white.withAlphaComponent(0.6)
        avatarView.layer.cornerRadius = 28
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        avatarView.layer.borderWidth = 1.0 / UIScreen.main.scale
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Name
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 1

        // Status
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.contentInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        statusLabel.numberOfLines = 1

        statusGlass.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusGlass.topAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: statusGlass.leadingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: statusGlass.trailingAnchor, constant: -4),
            statusLabel.bottomAnchor.constraint(equalTo: statusGlass.bottomAnchor, constant: -2),
            statusGlass.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        let textStack = UIStackView(arrangedSubviews: [nameLabel, statusGlass])
        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.alignment = .fill

        let h = UIStackView(arrangedSubviews: [avatarView, textStack])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            h.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            h.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            h.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, status: Status) {
        nameLabel.text = name
        switch status {
        case .teacherDone:
            statusLabel.text = "✅ Проверено учителем"
            statusGlass.backgroundColor = ResultStyle.okAccent.withAlphaComponent(0.28)
        case .llmDoneWaitTeacher:
            statusLabel.text = "🤖 Проверено ИИ, ждёт учителя"
            statusGlass.backgroundColor = ResultStyle.aiAccent.withAlphaComponent(0.28)
        case .llmPending:
            statusLabel.text = "⏳ На проверке (ИИ)"
            statusGlass.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        case .notPassed:
            statusLabel.text = "❌ Не прошёл"
            statusGlass.backgroundColor = UIColor.red.withAlphaComponent(0.30)
        }
    }
}
