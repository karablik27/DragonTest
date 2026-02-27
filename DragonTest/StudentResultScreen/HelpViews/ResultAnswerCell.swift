//
//  ResultAnswerCell.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class ResultAnswerCell: UITableViewCell {
    private let card = ResultGlassCard()

    // Header
    private let headerH = UIStackView()
    private let numberChip = PillLabel(style: .number)
    private let questionContainer = UIView()
    private let questionLbl = UILabel()

    private let answerTitle = PillLabel(text: "Ваш ответ", style: .white)

    private let answerBox = PaddedLabel()

    // AI
    private let aiHeader = UIStackView()
    private let aiIcon   = UIImageView(image: UIImage(systemName: "brain.head.profile"))
    private let aiChip   = PillLabel(text: "ИИ", style: .neutral)
    private let aiScorePill  = ScorePill(color: ResultStyle.aiScoreFill)
    private let aiComment = PaddedLabel()
    private let aiBlock = UIStackView()

    // Teacher
    private let teacherHeader = UIStackView()
    private let teacherIcon   = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.checkmark"))
    private let teacherChip   = PillLabel(text: "Учитель", style: .neutral)
    private let teacherScorePill  = ScorePill(color: ResultStyle.teacherScoreFill)
    private let teacherComment = PaddedLabel()
    private let teacherBlock = UIStackView()

    private let vStack = UIStackView()
    private let sepAfterHeader = UIView()
    private let sepAfterAnswer = UIView()
    private let sepAfterAI = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // ВОПРОС
        questionLbl.font = ResultStyle.questionFont
        questionLbl.textColor = .white
        questionLbl.numberOfLines = 0
        questionLbl.textAlignment = .center

        questionContainer.addSubview(questionLbl)
        questionLbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionLbl.topAnchor.constraint(equalTo: questionContainer.topAnchor),
            questionLbl.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 8),
            questionLbl.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -8),
            questionLbl.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor)
        ])

        headerH.axis = .horizontal
        headerH.alignment = .center
        headerH.spacing = 12
        headerH.addArrangedSubview(numberChip)
        headerH.addArrangedSubview(questionContainer)

        // ——— ПУЗЫРЬ ОТВЕТА С ПАДДИНГАМИ ———
        answerBox.font = ResultStyle.answerFont
        answerBox.textColor = .white
        answerBox.numberOfLines = 0
        answerBox.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        answerBox.layer.cornerRadius = ResultStyle.answerRadius
        answerBox.clipsToBounds = true
        answerBox.textAlignment = .natural
        answerBox.contentInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        answerBox.lineBreakMode = .byWordWrapping

        let answerV = UIStackView(arrangedSubviews: [answerTitle, answerBox])
        answerV.axis = .vertical
        answerV.spacing = 8

        // AI
        aiIcon.tintColor = ResultStyle.aiAccent
        aiIcon.preferredSymbolConfiguration = .init(pointSize: 18, weight: .medium)

        aiHeader.axis = .horizontal
        aiHeader.alignment = .center
        aiHeader.spacing = 8
        aiHeader.addArrangedSubview(aiIcon)
        aiHeader.addArrangedSubview(aiChip)
        aiHeader.addArrangedSubview(UIView())

        aiComment.font = ResultStyle.commentFont
        aiComment.textColor = .white
        aiComment.numberOfLines = 0
        aiComment.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        aiComment.layer.cornerRadius = 14
        aiComment.clipsToBounds = true
        aiComment.textAlignment = .natural
        aiComment.contentInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        aiComment.lineBreakMode = .byWordWrapping

        aiBlock.addArrangedSubview(aiHeader)
        aiBlock.addArrangedSubview(aiScorePill)
        aiBlock.addArrangedSubview(aiComment)
        aiBlock.axis = .vertical
        aiBlock.spacing = 8

        // Teacher
        teacherIcon.tintColor = ResultStyle.teacherAccent
        teacherIcon.preferredSymbolConfiguration = .init(pointSize: 18, weight: .medium)

        teacherHeader.axis = .horizontal
        teacherHeader.alignment = .center
        teacherHeader.spacing = 8
        teacherHeader.addArrangedSubview(teacherIcon)
        teacherHeader.addArrangedSubview(teacherChip)
        teacherHeader.addArrangedSubview(UIView())

        teacherComment.font = ResultStyle.commentFont
        teacherComment.textColor = .white
        teacherComment.numberOfLines = 0
        teacherComment.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        teacherComment.layer.cornerRadius = 14
        teacherComment.clipsToBounds = true
        teacherComment.textAlignment = .natural
        teacherComment.contentInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        teacherComment.lineBreakMode = .byWordWrapping

        teacherBlock.addArrangedSubview(teacherHeader)
        teacherBlock.addArrangedSubview(teacherScorePill)
        teacherBlock.addArrangedSubview(teacherComment)
        teacherBlock.axis = .vertical
        teacherBlock.spacing = 8

        // MAIN STACK
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.addArrangedSubview(headerH)
        configureSeparator(sepAfterHeader)
        vStack.addArrangedSubview(sepAfterHeader)
        vStack.addArrangedSubview(answerV)
        configureSeparator(sepAfterAnswer)
        vStack.addArrangedSubview(sepAfterAnswer)
        vStack.addArrangedSubview(aiBlock)
        configureSeparator(sepAfterAI)
        vStack.addArrangedSubview(sepAfterAI)
        vStack.addArrangedSubview(teacherBlock)

        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),

            numberChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 54),
            answerBox.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            aiComment.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            teacherComment.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    private func configureSeparator(_ view: UIView) {
        view.backgroundColor = ResultStyle.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
    }

    // Configure без изменений по логике
    func configure(answer: StudentAnswer, questionText: String, number: Int) {
        numberChip.setText("№ \(number)")
        questionLbl.text = questionText

        if let t = answer.textAnswer, !t.isEmpty {
            answerBox.text = t
        } else if let idx = answer.selectedIndex {
            answerBox.text = "Вариант №\(idx + 1)"
        } else {
            answerBox.text = "—"
        }

        let hasAI = answer.llmScore != nil || ((answer.llmComment ?? "").isEmpty == false)
        if let s = answer.llmScore { aiScorePill.setText("\(s)") } else { aiScorePill.setText("—") }
        if let c = answer.llmComment, !c.isEmpty { aiComment.text = "  \(c)  "; aiComment.isHidden = false }
        else { aiComment.text = nil; aiComment.isHidden = true }

        let hasTeacher = answer.teacherScore != nil || ((answer.teacherComment ?? "").isEmpty == false)
        if let s = answer.teacherScore { teacherScorePill.setText("\(s)") } else { teacherScorePill.setText("—") }
        if let c = answer.teacherComment, !c.isEmpty { teacherComment.text = "  \(c)  "; teacherComment.isHidden = false }
        else { teacherComment.text = nil; teacherComment.isHidden = true }

        aiBlock.isHidden = !hasAI
        teacherBlock.isHidden = !hasTeacher
        sepAfterAnswer.isHidden = !hasAI && !hasTeacher
        sepAfterAI.isHidden = !hasAI || !hasTeacher
    }
}
