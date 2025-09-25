//
//  StudentResultViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 25.09.2025.
//

import UIKit

final class StudentResultViewController: UIViewController {
    private let test: Test
    private let attempt: StudentAttempt
    private let resultService: ResultServiceProtocol

    private let statusLabel = UILabel()
    private let teacherLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private var result: TestResult?

    init(test: Test, attempt: StudentAttempt, resultService: ResultServiceProtocol) {
        self.test = test
        self.attempt = attempt
        self.resultService = resultService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Результат: \(test.title)"
        view.backgroundColor = .systemBackground
        setupUI()
        loadResult()
    }

    private func setupUI() {
        statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "Загрузка результата..."

        teacherLabel.font = .systemFont(ofSize: 16, weight: .medium)
        teacherLabel.textAlignment = .center
        teacherLabel.textColor = .secondaryLabel
        teacherLabel.numberOfLines = 0
        teacherLabel.isHidden = true

        view.addSubview(statusLabel)
        view.addSubview(teacherLabel)
        view.addSubview(tableView)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        teacherLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.register(ResultAnswerCell.self, forCellReuseIdentifier: "ResultAnswerCell")

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            teacherLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            teacherLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            teacherLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: teacherLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadResult() {
        Task {
            do {
                if let result = try await resultService.fetchResult(testId: test.id, studentId: attempt.studentId) {
                    self.result = result
                    await MainActor.run {
                        self.statusLabel.text = "✅ Проверено. Балл: \(result.totalScore)"
                        if let teacherComment = result.teacherComment {
                            self.teacherLabel.isHidden = false
                            self.teacherLabel.text = "Комментарий учителя: \(teacherComment)"
                        }
                        self.tableView.reloadData()
                    }
                } else {
                    await MainActor.run {
                        self.statusLabel.text = "⏳ Работа на проверке..."
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "Ошибка загрузки результата"
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension StudentResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        result?.answers.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultAnswerCell", for: indexPath) as! ResultAnswerCell
        if let answer = result?.answers[indexPath.row] {
            // находим текст вопроса по id
            let questionText = test.questions.first(where: { $0.id == answer.questionId })?.text ?? "Неизвестный вопрос"
            cell.configure(answer: answer, questionText: questionText)
        }
        return cell
    }
}

// MARK: - Custom Cell
private final class ResultAnswerCell: UITableViewCell {
    private let questionLabel = UILabel()
    private let studentAnswerLabel = UILabel()
    private let scoreLabel = UILabel()
    private let teacherCommentLabel = UILabel()
    private let llmCommentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        questionLabel.font = .systemFont(ofSize: 16, weight: .bold)
        questionLabel.numberOfLines = 0

        studentAnswerLabel.font = .systemFont(ofSize: 15)
        studentAnswerLabel.numberOfLines = 0

        scoreLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        scoreLabel.textColor = .systemBlue

        teacherCommentLabel.font = .systemFont(ofSize: 14)
        teacherCommentLabel.textColor = .systemGreen
        teacherCommentLabel.numberOfLines = 0

        llmCommentLabel.font = .systemFont(ofSize: 14)
        llmCommentLabel.textColor = .systemOrange
        llmCommentLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [questionLabel, studentAnswerLabel, scoreLabel, teacherCommentLabel, llmCommentLabel])
        stack.axis = .vertical
        stack.spacing = 6

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(answer: StudentAnswer, questionText: String) {
        questionLabel.text = "Вопрос: \(questionText)"
        studentAnswerLabel.text = "Ваш ответ: " + (answer.textAnswer ?? (answer.selectedIndex.map { "Вариант №\($0+1)" } ?? "—"))
        scoreLabel.text = "Балл: \(answer.teacherScore ?? 0)"
        teacherCommentLabel.text = answer.teacherComment != nil ? "Учитель: \(answer.teacherComment!)" : nil
        llmCommentLabel.text = answer.llmComment != nil ? "ИИ: \(answer.llmComment!)" : nil
    }
}
