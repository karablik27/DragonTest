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
    private let llmSummaryLabel = UILabel()
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
        statusLabel.text = "result.loading".localized

        teacherLabel.font = .systemFont(ofSize: 16, weight: .medium)
        teacherLabel.textAlignment = .center
        teacherLabel.textColor = .secondaryLabel
        teacherLabel.numberOfLines = 0
        teacherLabel.isHidden = true

        llmSummaryLabel.font = .systemFont(ofSize: 15, weight: .regular)
        llmSummaryLabel.textAlignment = .center
        llmSummaryLabel.textColor = .systemOrange
        llmSummaryLabel.numberOfLines = 0
        llmSummaryLabel.isHidden = true

        view.addSubview(statusLabel)
        view.addSubview(teacherLabel)
        view.addSubview(llmSummaryLabel)
        view.addSubview(tableView)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        teacherLabel.translatesAutoresizingMaskIntoConstraints = false
        llmSummaryLabel.translatesAutoresizingMaskIntoConstraints = false
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

            llmSummaryLabel.topAnchor.constraint(equalTo: teacherLabel.bottomAnchor, constant: 8),
            llmSummaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            llmSummaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: llmSummaryLabel.bottomAnchor, constant: 20),
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
                        self.statusLabel.text = "result.checked".localized + "\(result.totalScore)"
                        if let teacherComment = result.teacherComment {
                            self.teacherLabel.isHidden = false
                            self.teacherLabel.text = "result.teacher_comment".localized + teacherComment
                        }
                        if let llmComment = result.llmComment {
                            self.llmSummaryLabel.isHidden = false
                            self.llmSummaryLabel.text = "result.ai_comment".localized + llmComment
                        }
                        self.tableView.reloadData()
                    }
                } else {
                    await MainActor.run {
                        self.statusLabel.text = "result.pending".localized
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusLabel.text = "result.error".localized
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
    private let llmScoreLabel = UILabel()
    private let llmCommentLabel = UILabel()
    private let teacherScoreLabel = UILabel()
    private let teacherCommentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        questionLabel.font = .systemFont(ofSize: 16, weight: .bold)
        questionLabel.numberOfLines = 0

        studentAnswerLabel.font = .systemFont(ofSize: 15)
        studentAnswerLabel.numberOfLines = 0

        llmScoreLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        llmScoreLabel.textColor = .systemOrange

        llmCommentLabel.font = .systemFont(ofSize: 14)
        llmCommentLabel.textColor = .systemOrange
        llmCommentLabel.numberOfLines = 0

        teacherScoreLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        teacherScoreLabel.textColor = .systemBlue

        teacherCommentLabel.font = .systemFont(ofSize: 14)
        teacherCommentLabel.textColor = .systemGreen
        teacherCommentLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            questionLabel,
            studentAnswerLabel,
            llmScoreLabel,
            llmCommentLabel,
            teacherScoreLabel,
            teacherCommentLabel
        ])
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
        questionLabel.text = "result.question".localized + questionText
        studentAnswerLabel.text = "result.your_answer".localized + (answer.textAnswer ?? (answer.selectedIndex.map { "result.option_number".localized + "\($0+1)" } ?? "—"))

        // ⚡️ ИИ-оценка
        if let llmScore = answer.llmScore {
            llmScoreLabel.text = "result.ai_score".localized + "\(llmScore)"
        } else {
            llmScoreLabel.text = "result.ai_not_checked".localized
        }
        llmCommentLabel.text = answer.llmComment != nil ? "result.ai_comment_label".localized + answer.llmComment! : nil

        // ⚡️ Учительская оценка
        if let teacherScore = answer.teacherScore {
            teacherScoreLabel.text = "result.teacher_score".localized + "\(teacherScore)"
        } else {
            teacherScoreLabel.text = "result.teacher_not_graded".localized
        }
        teacherCommentLabel.text = answer.teacherComment != nil ? "result.teacher_comment_label".localized + answer.teacherComment! : nil
    }
}
