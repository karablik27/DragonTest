//
//  TeacherReviewDetailViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 26.09.2025.
//

import UIKit

final class TeacherReviewDetailViewController: UIViewController {

    // MARK: - MVP
    private let presenter: TeacherReviewDetailPresenterProtocol

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var footerButton: PrimaryActionButton?

    // MARK: - Init (DI идёт в презентер)
    init(attempt: StudentAttempt,
         questions: [Questions],
         answerService: AnswerServiceProtocol,
         colors: [CGColor],
         testTitle: String)
    {
        self.presenter = TeacherReviewDetailPresenter(
            attempt: attempt,
            questions: questions,
            answerService: answerService,
            colors: colors,
            testTitle: testTitle
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupTable()
        setupKeyboardDismiss()

        presenter.attach(view: self)
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + 12
        tableView.scrollIndicatorInsets.bottom = view.safeAreaInsets.bottom
    }

    // MARK: - Nav
    private func setupNav() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        title = nil
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

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func endEditingTap() { view.endEditing(true) }

    // MARK: - Header (строится внутри вью)
    private func buildHeader(testTitle: String) {
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
    private func buildFooter(show: Bool) {
        guard show else {
            tableView.tableFooterView = UIView(
                frame: .init(x: 0, y: 0, width: view.bounds.width, height: 8)
            )
            footerButton = nil
            return
        }

        let button = PrimaryActionButton(title: "Сохранить результат")
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        self.footerButton = button

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

    // MARK: - Actions
    @objc private func saveTapped() {
        presenter.saveTapped()
    }
}

// MARK: - TableView
extension TeacherReviewDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.numberOfRows()
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "TeacherReviewAnswerCell",
            for: indexPath
        ) as! TeacherReviewAnswerCell

        let item = presenter.item(at: indexPath.row)
        cell.configure(
            number: indexPath.row + 1,
            answer: item.answer,
            questionText: item.questionText,
            isEditable: item.isEditable
        ) { [weak self] updated in
            self?.presenter.didUpdateAnswer(at: indexPath.row, to: updated)
        }
        return cell
    }
}

// MARK: - View protocol
extension TeacherReviewDetailViewController: TeacherReviewDetailViewProtocol {
    func applyBackground(colors: [CGColor]) {
        view.backgroundColor = .clear
        GradientBackground.attach(to: view, colors: colors)
    }

    func setHeader(testTitle: String) {
        buildHeader(testTitle: testTitle)
    }

    func showFooter(_ show: Bool) {
        buildFooter(show: show)
    }

    func setSaveEnabled(_ enabled: Bool) {
        footerButton?.isEnabled = enabled
        footerButton?.alpha = enabled ? 1.0 : 0.6
        footerButton?.isUserInteractionEnabled = enabled
    }

    func reloadAll() {
        tableView.reloadData()
    }

    func reloadRow(_ row: Int) {
        guard row < tableView.numberOfRows(inSection: 0) else { return }
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }

    func showMessage(title: String, message: String, onOK: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Ок", style: .default, handler: { _ in onOK?() }))
        present(alert, animated: true)
    }

    func pop() {
        navigationController?.popViewController(animated: true)
    }
}
