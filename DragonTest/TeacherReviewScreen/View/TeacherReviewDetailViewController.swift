//  TeacherReviewDetailViewController.swift
//  DragonTest

import UIKit

final class TeacherReviewDetailViewController: UIViewController {

    // MARK: - DI
    private let attempt: StudentAttempt
    private let answerService: AnswerServiceProtocol
    private var answers: [StudentAnswer]
    private let questions: [Questions]
    private let colors: [CGColor]
    private let testTitle: String
    private let isEditable: Bool

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var footerButton: PrimaryActionButton?

    // MARK: - Init
    init(attempt: StudentAttempt,
         questions: [Questions],
         answerService: AnswerServiceProtocol,
         colors: [CGColor],
         testTitle: String)
    {
        self.attempt = attempt
        self.questions = questions
        self.answerService = answerService
        self.colors = colors
        self.testTitle = testTitle
        self.isEditable = (attempt.reviewed == false)
        self.answers = attempt.result?.answers ?? attempt.answers
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupNav()
        setupTable()
        buildHeader()
        buildFooterIfNeeded()
        updateSaveButtonState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // подгоняем размеры header/footer по ширине
        if let header = tableView.tableHeaderView {
            let target = header.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: 1),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            if header.frame.height != target.height {
                header.frame.size.height = target.height
                tableView.tableHeaderView = header
            }
        }
        if let footer = tableView.tableFooterView {
            let target = footer.systemLayoutSizeFitting(
                CGSize(width: view.bounds.width, height: 1),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            if footer.frame.height != target.height {
                footer.frame.size.height = target.height
                tableView.tableFooterView = footer
            }
        }
        // небольшой отступ, чтобы последняя карточка не прилипала к таббару
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + 12
        tableView.scrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - BG
    private func setupBackground() {
        view.backgroundColor = .clear
        GradientBackground.attach(to: view, colors: colors)
    }

    private func setupNav() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        title = nil
    }

    // MARK: - Header (стекло + плашка с названием теста)
    private func buildHeader() {
        let headerCard = ResultGlassCard()

        let titleLabel = UILabel()
        titleLabel.text = "Проверка ответов"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = .white.withAlphaComponent(0.95)

        let testTitlePill = PillLabel(text: testTitle, style: .white)

        let stack = UIStackView(arrangedSubviews: [titleLabel, testTitlePill])
        stack.axis = .vertical
        stack.spacing = 10

        headerCard.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -14)
        ])

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(headerCard)
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            headerCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            headerCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])

        // автоподгон стартовой высоты
        container.layoutIfNeeded()
        let size = container.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: 1),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: size)
        tableView.tableHeaderView = container
    }

    // MARK: - Footer (кнопка внизу списка)
    private func buildFooterIfNeeded() {
        guard isEditable else {
            tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: view.bounds.width, height: 8))
            return
        }

        let button = PrimaryActionButton(title: "Сохранить результат")
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        footerButton = button

        let footerCard = ResultGlassCard(radius: 20)
        footerCard.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: footerCard.topAnchor, constant: 14),
            button.leadingAnchor.constraint(equalTo: footerCard.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: footerCard.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: footerCard.bottomAnchor, constant: -14),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(footerCard)
        footerCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerCard.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            footerCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            footerCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            footerCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            container.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])

        container.layoutIfNeeded()
        let size = container.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: 1),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: size)
        tableView.tableFooterView = container
    }

    // MARK: - Table
    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        tableView.keyboardDismissMode = .onDrag

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(TeacherReviewAnswerCell.self,
                           forCellReuseIdentifier: "TeacherReviewAnswerCell")

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateSaveButtonState() {
        guard let button = footerButton else { return }
        let allScored = answers.allSatisfy { $0.teacherScore != nil }
        button.isEnabled = allScored
        button.alpha = allScored ? 1.0 : 0.6
        button.isUserInteractionEnabled = allScored
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func endEditingTap() { view.endEditing(true) }

    // MARK: - Save
    @objc private func saveTapped() {
        view.endEditing(true)

        // защита на всякий
        guard answers.allSatisfy({ $0.teacherScore != nil }) else {
            let alert = UIAlertController(
                title: "Не все вопросы оценены",
                message: "Поставьте баллы за каждый ответ перед сохранением.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ок", style: .default))
            present(alert, animated: true)
            return
        }

        let totalScore = answers.compactMap { $0.teacherScore }.reduce(0, +)
        let completed = answers.filter { ($0.teacherScore ?? 0) >= 4 }.count

        let result = TestResult(
            id: attempt.result?.id ?? UUID().uuidString,
            testId: attempt.testId,
            studentId: attempt.studentId,
            answers: answers,
            totalScore: totalScore,
            completed: completed,
            capturedDragon: totalScore >= 320,
            teacherComment: "Оценка учителя сохранена",
            llmComment: attempt.result?.llmComment,
            llmReviewedAt: attempt.result?.llmReviewedAt,
            teacherReviewedAt: Date()
        )

        Task {
            do {
                try await answerService.reviewAttempt(attempt.id, result: result)
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Сохранено",
                        message: "Результат проверки отправлен",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ок", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Ошибка",
                        message: "Не удалось сохранить результат",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ок", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - TableView
extension TeacherReviewDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        answers.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TeacherReviewAnswerCell",
            for: indexPath
        ) as! TeacherReviewAnswerCell

        let answer = answers[indexPath.row]
        let questionText = questions.first(where: { $0.id == answer.questionId })?.text ?? "Вопрос не найден"

        cell.configure(
            number: indexPath.row + 1,
            answer: answer,
            questionText: questionText,
            isEditable: isEditable
        ) { [weak self] updated in
            guard let self else { return }
            self.answers[indexPath.row] = updated
            self.updateSaveButtonState()
        }
        return cell
    }
}

////////////////////////////////////////////////////////////
// MARK: - PrimaryActionButton (красивый градиент)
////////////////////////////////////////////////////////////

final class PrimaryActionButton: UIControl {
    private let gradient = CAGradientLayer()
    private let titleLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 16
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        // градиент в стиле синей «учительской» плашки
        gradient.colors = [
            UIColor(red: 0.12, green: 0.49, blue: 0.98, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.33, blue: 0.87, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradient, at: 0)

        // лёгкая тень
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 8)

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])

        // тап
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); gradient.frame = bounds }
    @objc private func tapHandler() { sendActions(for: .touchUpInside) }
}

////////////////////////////////////////////////////////////
// MARK: - Cells (как раньше, но поддерживают isEditable)
////////////////////////////////////////////////////////////

private final class TeacherReviewAnswerCell: UITableViewCell {

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
    private let teacherScoreInput = ScoreEditPill(color: ResultStyle.teacherScoreFill)
    private let teacherCommentView = GlassTextView()

    private let vStack = UIStackView()

    private var onUpdate: ((StudentAnswer) -> Void)?
    private var currentAnswer: StudentAnswer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // вопрос
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

        // ответ
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

        // Учитель
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

////////////////////////////////////////////////////////////
// MARK: - Inputs
////////////////////////////////////////////////////////////

final class ScoreEditPill: UIControl, UITextFieldDelegate {
    private let bg = CAGradientLayer()
    private let tf = UITextField()
    var onValueChanged: ((Int?) -> Void)?

    init(color: UIColor) {
        super.init(frame: .zero)
        layer.cornerRadius = 16
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        let darker = color.darker(by: 0.16)
        bg.startPoint = CGPoint(x: 0, y: 0.5)
        bg.endPoint   = CGPoint(x: 1, y: 0.5)
        bg.colors = [color.cgColor, darker.cgColor]
        layer.insertSublayer(bg, at: 0)

        tf.font = .systemFont(ofSize: 20, weight: .bold)
        tf.textAlignment = .center
        tf.textColor = .white
        tf.keyboardType = .numberPad
        tf.attributedPlaceholder = NSAttributedString(
            string: "—",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        tf.delegate = self
        tf.inputAccessoryView = makeDoneToolbar()

        addSubview(tf)
        tf.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            tf.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            tf.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); bg.frame = bounds }

    func set(value: Int?) { tf.text = value.map(String.init) }

    func setEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        tf.isEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        let ns = textField.text as NSString? ?? ""
        let new = ns.replacingCharacters(in: range, with: string)
        if new.isEmpty { onValueChanged?(nil); return true }
        guard let v = Int(new), v >= 0, v <= 10 else { return false }
        onValueChanged?(v)
        return true
    }

    private func makeDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(endEdit))
        tb.items = [flex, done]
        return tb
    }
    @objc private func endEdit() { endEditing(true) }
}

private final class GlassTextView: UIView, UITextViewDelegate {
    private let glass = FieldGlass()
    private let tv = UITextView()
    var onChange: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(glass)
        glass.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.font = ResultStyle.commentFont
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        tv.delegate = self
        tv.keyboardDismissMode = .interactive
        tv.inputAccessoryView = makeDoneToolbar()

        addSubview(tv)
        tv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: topAnchor),
            tv.leadingAnchor.constraint(equalTo: leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: trailingAnchor),
            tv.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(text: String) { tv.text = text }
    func setEditable(_ editable: Bool) {
        tv.isEditable = editable
        tv.isSelectable = editable
    }

    func textViewDidChange(_ textView: UITextView) { onChange?(textView.text) }

    private func makeDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(endEdit))
        tb.items = [flex, done]
        return tb
    }
    @objc private func endEdit() { endEditing(true) }
}
