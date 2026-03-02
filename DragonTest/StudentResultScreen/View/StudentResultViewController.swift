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
    private let closeButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var tableTopConstraint: NSLayoutConstraint?

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
        setupTopBar()
        setupTable()

        presenter.attach(view: self)
        presenter.viewDidLoad()

        recomputeSummary()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyTopLayout()
        updateBottomInsets()

        if let header = tableView.tableHeaderView {
            let width = effectiveTableWidth()
            let target = header.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            if header.frame.height != target.height || header.frame.width != width {
                header.frame.size.width = width
                header.frame.size.height = target.height
                tableView.tableHeaderView = header
            }
        }
        updateScrollBehavior()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateBottomInsets()
    }

    // MARK: - Background (same as DragonTest)
    private func setupBackground() {
        GradientBackground.attach(to: view, colors: colors)
    }

    // MARK: - Top Bar
    private func setupTopBar() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        closeButton.layer.cornerRadius = 15
        closeButton.clipsToBounds = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
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
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 28, right: 0)
        tableView.verticalScrollIndicatorInsets.bottom = 28
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.sectionHeaderTopPadding = 0
        tableView.bounces = false

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ResultAnswerCell.self, forCellReuseIdentifier: "ResultAnswerCell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48)
        NSLayoutConstraint.activate([
            tableTopConstraint!,
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
        let topRow = UIStackView(arrangedSubviews: [testTitlePill, UIView(), closeButton])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 10
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])

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
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: container.topAnchor),
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        recomputeSummary()

        container.layoutIfNeeded()
        let width = effectiveTableWidth()
        let target = container.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: CGSize(width: width, height: target.height))
        return container
    }

    // MARK: - Summary logic
    private func recomputeSummary() {
        let rows = presenter.numberOfRows()
        guard rows > 0 else {
            pointsPill.set(value: "—")
            gradePill.set(value: "—")
            whoPill.set(value: "—")
            relayoutHeader()
            return
        }

        var total = 0
        var teacherScoresCount = 0
        var llmScoresCount = 0

        for i in 0..<rows {
            guard let item = presenter.answer(at: i) else { continue }
            let a = item.answer
            if let t = a.teacherScore {
                total += t
                teacherScoresCount += 1
            } else if let m = a.llmScore {
                total += m
                llmScoresCount += 1
            }
        }

        let scoredCount = teacherScoresCount + llmScoresCount
        guard scoredCount > 0 else {
            pointsPill.set(value: "—")
            gradePill.set(value: "—")
            whoPill.set(value: "—")
            relayoutHeader()
            return
        }

        pointsPill.set(value: "\(total)")

        let maxScore = rows * 10
        let grade10 = maxScore > 0 ? Int(round(Double(total) / Double(maxScore) * 10.0)) : 0
        gradePill.set(value: scoredCount == rows ? "\(grade10)" : "—")

        if teacherScoresCount == rows {
            whoPill.set(value: "Учитель")
        } else if llmScoresCount == rows {
            whoPill.set(value: "ИИ")
        } else if teacherScoresCount > 0 && llmScoresCount > 0 {
            whoPill.set(value: "Уч/ИИ")
        } else {
            whoPill.set(value: teacherScoresCount > 0 ? "Учитель" : "ИИ")
        }

        relayoutHeader()
    }

    private func relayoutHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let width = effectiveTableWidth()
        let newSize = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != newSize.height || header.frame.width != width {
            header.frame.size.width = width
            header.frame.size.height = newSize.height
            tableView.tableHeaderView = header
        }
        updateScrollBehavior()
    }

    private func effectiveTableWidth() -> CGFloat {
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        return width > 0 ? width : UIScreen.main.bounds.width
    }

    private func applyTopLayout() {
        let sceneStatusBar = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let fallbackTop = sceneStatusBar > 0 ? sceneStatusBar : view.safeAreaInsets.top
        let topInset = min(max(fallbackTop, 20), 60)

        tableTopConstraint?.constant = topInset + 18
    }

    private func updateBottomInsets() {
        let tabBarInset = visibleTabBarHeight()
        let safeBottom = view.safeAreaInsets.bottom
        let bottom = max(28, max(tabBarInset, safeBottom) + 12)

        if tableView.contentInset.bottom != bottom {
            tableView.contentInset.bottom = bottom
            tableView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }

    private func visibleTabBarHeight() -> CGFloat {
        if let tabBar = tabBarController?.tabBar,
           !tabBar.isHidden,
           tabBar.alpha > 0.01 {
            return tabBar.bounds.height
        }

        var parentVC = parent
        while let current = parentVC {
            if let tabController = current as? UITabBarController {
                let bar = tabController.tabBar
                if !bar.isHidden, bar.alpha > 0.01 {
                    return bar.bounds.height
                }
                return 0
            }
            parentVC = current.parent
        }
        return 0
    }

    private func updateScrollBehavior() {
        tableView.layoutIfNeeded()
        let visibleHeight = tableView.bounds.height - tableView.adjustedContentInset.top - tableView.adjustedContentInset.bottom
        tableView.isScrollEnabled = tableView.contentSize.height > visibleHeight + 1
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
        updateScrollBehavior()
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
