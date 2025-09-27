//  StudentResultViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 25.09.2025.
//

import UIKit

final class StudentResultViewController: UIViewController, StudentResultViewProtocol {

    // MARK: - DI
    private let presenter: StudentResultPresenterProtocol
    private let colors: [CGColor]

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // summary (glass) header
    private let summaryCard = ResultGlassCard()
    private let testTitlePill = PillLabel(text: "Тест", style: .white)
    private let metricsRow = UIStackView()
    private let pointsPill  = MetricPill(title: "Баллы")
    private let gradePill   = MetricPill(title: "Оценка")
    private let whoPill     = MetricPill(title: "Проверил")
    private var cachedTestTitle: String?
    var onClose: (() -> Void)?

    // MARK: - Init
    init(test: Test,
         attempt: StudentAttempt,
         resultService: ResultServiceProtocol,
         colors: [CGColor]) {
        self.colors = colors
        let presenter = StudentResultPresenter(
            test: test,
            attempt: attempt,
            resultService: resultService,
            onClose: nil
        )
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupNavigation()
        setupTable()

        presenter.attach(view: self)
        presenter.viewDidLoad()

        recomputeSummary()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let target = header.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != target.height {
            header.frame.size.height = target.height
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Background (same as DragonTest)
    private func setupBackground() {
        GradientBackground.attach(to: view, colors: colors)
    }

    // MARK: - Navigation
    private func setupNavigation() {
        let back = UIBarButtonItem(
            image: UIImage(systemName: "chevron.up"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.leftBarButtonItem = back
        navigationController?.navigationBar.tintColor = .label
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        title = nil
    }

    @objc private func closeTapped() {
        presenter.closeTapped()
        onClose?()
    }

    // MARK: - Table
    private func setupTable() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 28, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ResultAnswerCell.self, forCellReuseIdentifier: "ResultAnswerCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.tableHeaderView = makeHeaderView()
    }

    private func makeHeaderView() -> UIView {
        // ---- summary glass card ----
        let card = summaryCard
        card.translatesAutoresizingMaskIntoConstraints = false

        testTitlePill.setText(cachedTestTitle ?? "Тест")
        let topRow = UIStackView(arrangedSubviews: [testTitlePill, UIView()])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10

        metricsRow.axis = .horizontal
        metricsRow.alignment = .fill
        metricsRow.distribution = .fillEqually
        metricsRow.spacing = 12
        metricsRow.addArrangedSubview(pointsPill)
        metricsRow.addArrangedSubview(gradePill)
        metricsRow.addArrangedSubview(whoPill)

        let stack = UIStackView(arrangedSubviews: [topRow, metricsRow])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            container.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])

        recomputeSummary()

        container.layoutIfNeeded()
        let target = container.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: target.height))
        return container
    }

    // MARK: - Summary logic
    private func recomputeSummary() {
        let rows = presenter.numberOfRows()
        guard rows > 0 else {
            pointsPill.set(value: "0")
            gradePill.set(value: "0")
            whoPill.set(value: "ИИ")
            relayoutHeader()
            return
        }

        var total = 0
        var teacherCoveredAll = true

        for i in 0..<rows {
            guard let item = presenter.answer(at: i) else { continue }
            let a = item.answer
            if let t = a.teacherScore {
                total += t
            } else if let m = a.llmScore {
                total += m
                teacherCoveredAll = false
            } else {
                teacherCoveredAll = false
            }
        }

        let maxScore = rows * 10
        let grade10 = maxScore > 0 ? Int(round(Double(total) / Double(maxScore) * 10.0)) : 0

        pointsPill.set(value: "\(total)")
        gradePill.set(value: "\(grade10)")
        whoPill.set(value: teacherCoveredAll ? "Учитель" : "ИИ")

        relayoutHeader()
    }

    private func relayoutHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let newSize = header.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != newSize.height {
            header.frame.size.height = newSize.height
            tableView.tableHeaderView = header
        }
    }

    // MARK: - StudentResultViewProtocol
    func setTitle(_ text: String) {
        navigationItem.title = nil
        title = nil
        let cleaned = text.replacingOccurrences(of: "Результат:", with: "").trimmingCharacters(in: .whitespaces)
        cachedTestTitle = cleaned.isEmpty ? text : cleaned
        testTitlePill.setText(cachedTestTitle!)
        relayoutHeader()
    }

    func showStatus(_ text: String) {
        recomputeSummary()
    }

    func showTeacherComment(_ text: String?, hidden: Bool) {
        recomputeSummary()
    }

    func showLLMSummary(_ text: String?, hidden: Bool) {
        recomputeSummary()
    }

    func reloadAnswers() {
        tableView.reloadData()
        recomputeSummary()
    }
}

// MARK: - UITableViewDataSource
extension StudentResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.numberOfRows()
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ResultAnswerCell",
            for: indexPath
        ) as! ResultAnswerCell
        cell.backgroundColor = .clear

        if let item = presenter.answer(at: indexPath.row) {
            cell.configure(answer: item.answer, questionText: item.questionText, number: indexPath.row + 1)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension StudentResultViewController: UITableViewDelegate {}
