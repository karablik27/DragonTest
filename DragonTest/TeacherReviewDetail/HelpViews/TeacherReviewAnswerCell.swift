//
//  TeacherReviewAnswerCell.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class TeacherReviewAnswerCell: UITableViewCell {

    private let card = ResultGlassCard()

    // Header
    private let headerH = UIStackView()
    private let numberChip = PillLabel(style: .number)
    private let questionContainer = UIView()
    private let questionLbl = UILabel()

    // Ответ
    private let answerTitle = PillLabel(text: "Ваш ответ", style: .white)
    private let answerBox   = PaddedLabel()

    // ИИ
    private let aiHeader = UIStackView()
    private let aiIcon   = UIImageView(image: UIImage(systemName: "brain.head.profile"))
    private let aiChip   = PillLabel(text: "ИИ", style: .neutral)
    private let aiScorePill  = ScorePill(color: ResultStyle.aiScoreFill)
    private let aiComment    = PaddedLabel()

    // Учитель
    private let teacherHeader = UIStackView()
    private let teacherIcon   = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.checkmark"))
    private let teacherChip   = PillLabel(text: "Учитель", style: .neutral)
    private let teacherScoreInput = ScoreEditPillTeacher(color: ResultStyle.teacherScoreFill)
    private let teacherCommentView = GlassTextView()

    private let vStack = UIStackView()

    private var onUpdate: ((StudentAnswer) -> Void)?
    private var currentAnswer: StudentAnswer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

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

        // ИИ
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

        let aiBlock = UIStackView(arrangedSubviews: [aiHeader, aiScorePill, aiComment])
        aiBlock.axis = .vertical
        aiBlock.spacing = 8

        teacherIcon.tintColor = ResultStyle.teacherAccent
        teacherIcon.preferredSymbolConfiguration = .init(pointSize: 18, weight: .medium)

        teacherHeader.axis = .horizontal
        teacherHeader.alignment = .center
        teacherHeader.spacing = 8
        teacherHeader.addArrangedSubview(teacherIcon)
        teacherHeader.addArrangedSubview(teacherChip)
        teacherHeader.addArrangedSubview(UIView())

        let teacherBlock = UIStackView(arrangedSubviews: [teacherHeader, teacherScoreInput, teacherCommentView])
        teacherBlock.axis = .vertical
        teacherBlock.spacing = 8

        // MAIN
        vStack.axis = .vertical
        vStack.spacing = 16
        vStack.addArrangedSubview(headerH)
        vStack.addArrangedSubview(makeSeparator())
        vStack.addArrangedSubview(answerV)
        vStack.addArrangedSubview(makeSeparator())
        vStack.addArrangedSubview(aiBlock)
        vStack.addArrangedSubview(makeSeparator())
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
            teacherScoreInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        // callbacks
        teacherScoreInput.onValueChanged = { [weak self] value in
            guard let self, var ans = self.currentAnswer else { return }
            ans.teacherScore = value
            ans.finalScore = value
            self.currentAnswer = ans
            self.onUpdate?(ans)
        }
        teacherCommentView.onChange = { [weak self] text in
            guard let self, var ans = self.currentAnswer else { return }
            ans.teacherComment = text
            self.currentAnswer = ans
            self.onUpdate?(ans)
            self.relayout()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = ResultStyle.separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        return v
    }

    private func relayout() {
        var v: UIView? = self
        while v != nil, !(v is UITableView) { v = v?.superview }
        (v as? UITableView).map { $0.beginUpdates(); $0.endUpdates() }
    }

    // PUBLIC
    func configure(number: Int,
                   answer: StudentAnswer,
                   questionText: String,
                   isEditable: Bool,
                   onUpdate: @escaping (StudentAnswer)->Void)
    {
        self.currentAnswer = answer
        self.onUpdate = onUpdate

        numberChip.setText("№ \(number)")
        questionLbl.text = questionText

        if let t = answer.textAnswer, !t.isEmpty {
            answerBox.text = t
        } else if let idx = answer.selectedIndex {
            answerBox.text = "Вариант №\(idx + 1)"
        } else {
            answerBox.text = "—"
        }

        aiScorePill.set(value: answer.llmScore.map(String.init) ?? "—")
        if let c = answer.llmComment, !c.isEmpty {
            aiComment.text = "  \(c)  "
            aiComment.isHidden = false
        } else {
            aiComment.text = nil
            aiComment.isHidden = true
        }

        teacherScoreInput.set(value: answer.teacherScore)
        teacherScoreInput.setEnabled(isEditable)
        teacherCommentView.set(text: answer.teacherComment ?? "")
        teacherCommentView.setEditable(isEditable)
        teacherCommentView.alpha = isEditable ? 1.0 : 0.6
    }
}
