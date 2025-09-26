//
//  TeacherReviewDetailViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 25.09.2025.
//

import UIKit

final class TeacherReviewDetailViewController: UIViewController {
    
    private let attempt: StudentAttempt
    private let answerService: AnswerServiceProtocol
    private var answers: [StudentAnswer]
    private let questions: [Questions]
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let saveButton = UIButton(type: .system)
    
    init(attempt: StudentAttempt, questions: [Questions], answerService: AnswerServiceProtocol) {
        self.attempt = attempt
        self.questions = questions
        self.answerService = answerService
        self.answers = attempt.result?.answers ?? attempt.answers
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Проверка ответов"
        view.backgroundColor = .systemBackground
        setupTable()
        setupSaveButton()
        setupKeyboardDismiss()
    }
    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReviewAnswerCell.self, forCellReuseIdentifier: "ReviewAnswerCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70)
        ])
    }
    
    private func setupSaveButton() {
        saveButton.setTitle("💾 Сохранить результат", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveButton.backgroundColor = .systemBlue
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 10
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func endEditingTap() {
        view.endEditing(true)
    }
    
    @objc private func saveTapped() {
        view.endEditing(true)

        let notScored = answers.filter { $0.teacherScore == nil }
        if !notScored.isEmpty {
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
            llmComment: attempt.result?.llmComment
        )

        Task {
            do {
                try await answerService.reviewAttempt(attempt.id, result: result)
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Сохранено",
                        message: "Результат проверки отправлен ✅",
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewAnswerCell", for: indexPath) as! ReviewAnswerCell
        let answer = answers[indexPath.row]
        let questionText = questions.first(where: { $0.id == answer.questionId })?.text ?? "Вопрос не найден"
        cell.configure(answer: answer, questionText: questionText) { [weak self] updated in
            self?.answers[indexPath.row] = updated
        }
        return cell
    }
}


// MARK: - Custom Cell
private final class ReviewAnswerCell: UITableViewCell, UITextFieldDelegate {
    
    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let llmLabel = UILabel()
    private let teacherLabel = UILabel()
    private let scoreField = UITextField()
    private let commentField = UITextField()
    
    private var onUpdate: ((StudentAnswer) -> Void)?
    private var currentAnswer: StudentAnswer?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        questionLabel.font = .systemFont(ofSize: 16, weight: .bold)
        questionLabel.numberOfLines = 0
        
        answerLabel.font = .systemFont(ofSize: 14)
        answerLabel.textColor = .label
        answerLabel.numberOfLines = 0
        
        llmLabel.font = .systemFont(ofSize: 13)
        llmLabel.textColor = .systemGreen
        llmLabel.numberOfLines = 0
        
        teacherLabel.font = .systemFont(ofSize: 13)
        teacherLabel.textColor = .systemBlue
        teacherLabel.numberOfLines = 0
        
        scoreField.placeholder = "Балл учителя (0–10)"
        scoreField.borderStyle = .roundedRect
        scoreField.keyboardType = .numberPad
        scoreField.widthAnchor.constraint(equalToConstant: 120).isActive = true
        scoreField.addTarget(self, action: #selector(scoreChanged), for: .editingChanged)
        scoreField.delegate = self
        scoreField.inputAccessoryView = makeDoneToolbar()
        
        commentField.placeholder = "Комментарий учителя"
        commentField.borderStyle = .roundedRect
        commentField.addTarget(self, action: #selector(commentChanged), for: .editingChanged)
        commentField.delegate = self
        commentField.returnKeyType = .done
        commentField.inputAccessoryView = makeDoneToolbar()
        
        let vStack = UIStackView(arrangedSubviews: [questionLabel, answerLabel, llmLabel, teacherLabel, scoreField, commentField])
        vStack.axis = .vertical
        vStack.spacing = 6
        
        contentView.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(answer: StudentAnswer, questionText: String, onUpdate: @escaping (StudentAnswer) -> Void) {
        self.currentAnswer = answer
        self.onUpdate = onUpdate
        
        questionLabel.text = "Вопрос: \(questionText)"
        answerLabel.text = "Ответ ученика: " + (answer.textAnswer ?? (answer.selectedIndex.map { "Вариант №\($0+1)" } ?? "—"))
        
        // ⚡️ ИИ
        if let score = answer.llmScore, let comment = answer.llmComment {
            llmLabel.text = "ИИ → Балл: \(score)\nКомментарий: \(comment)"
        } else {
            llmLabel.text = "ИИ ещё не проверял"
        }
        
        // ⚡️ Учитель
        if let score = answer.teacherScore {
            teacherLabel.text = "Учитель → Балл: \(score)"
        } else {
            teacherLabel.text = "Учитель ещё не оценил"
        }
        
        scoreField.text = answer.teacherScore.map { "\($0)" }
        commentField.text = answer.teacherComment
    }
    
    @objc private func scoreChanged() {
        guard var ans = currentAnswer else { return }
        if let v = Int(scoreField.text ?? "") {
            ans.teacherScore = max(0, min(10, v))
        } else {
            ans.teacherScore = nil
        }
        ans.finalScore = ans.teacherScore
        currentAnswer = ans
        onUpdate?(ans)
    }
    
    @objc private func commentChanged() {
        guard var ans = currentAnswer else { return }
        ans.teacherComment = commentField.text
        currentAnswer = ans
        onUpdate?(ans)
    }
    
    private func makeDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(dismissKeyboard))
        tb.items = [flex, done]
        return tb
    }
    
    @objc private func dismissKeyboard() {
        contentView.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentView.endEditing(true)
        return true
    }
}
