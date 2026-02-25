//
//  NotificationsScreenViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 25.02.2026.
//

import UIKit

private struct NotificationCardItem {
    let status: String
    let testTitle: String
    let reviewer: String
    let score: Int?
    let isFinal: Bool
    let isInvitation: Bool
    let isPreliminary: Bool
}

private enum NotificationFilter: Int, CaseIterable {
    case all
    case final
    case preliminary
    case invitation

    var title: String {
        switch self {
        case .all: return "Все"
        case .final: return "Итог"
        case .preliminary: return "ИИ"
        case .invitation: return "Пригл."
        }
    }

    func matches(_ item: NotificationCardItem) -> Bool {
        switch self {
        case .all:
            return true
        case .final:
            return item.isFinal
        case .preliminary:
            return item.isPreliminary
        case .invitation:
            return item.isInvitation
        }
    }

    var emptyStateText: String {
        switch self {
        case .all:
            return "Пока нет уведомлений"
        case .final:
            return "Нет итоговых уведомлений"
        case .preliminary:
            return "Нет уведомлений ИИ-проверки"
        case .invitation:
            return "Нет приглашений в тесты"
        }
    }
}

final class NotificationsScreenViewController: UIViewController {
    private var rawNotifications: [String]
    private var allItems: [NotificationCardItem] = []
    private var filteredItems: [NotificationCardItem] = []
    private var selectedFilter: NotificationFilter = .all

    private let backgroundGradient = CAGradientLayer()
    private let controlsCard = UIView()
    private let filterPillContainer = UIView()
    private let filterButtonsStack = UIStackView()
    private var filterButtons: [UIButton] = []
    private var filterSelectedBackgroundColor: UIColor = .clear
    private var filterNormalTextColor: UIColor = .label
    private var filterSelectedTextColor: UIColor = .label
    private let summaryLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStateLabel = UILabel()

    init(notifications: [String]) {
        self.rawNotifications = notifications
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        applyFilter(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateBackgroundStyle()
    }

    func updateNotifications(_ items: [String]) {
        rawNotifications = items
        applyFilter(animated: false)
    }

    private func setupNavigationBar() {
        title = "Уведомления"
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(white: 0.06, alpha: 0.72)
            } else {
                return UIColor(white: 0.95, alpha: 0.82)
            }
        }
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func setupUI() {
        setupBackground()
        setupControlsCard()
        setupTable()
    }

    private func setupBackground() {
        view.backgroundColor = .clear
        backgroundGradient.name = "notificationsBackgroundGradient"
        backgroundGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        backgroundGradient.locations = [0.0, 0.45, 1.0]
        view.layer.insertSublayer(backgroundGradient, at: 0)
        updateBackgroundStyle()
    }

    private func updateBackgroundStyle() {
        if traitCollection.userInterfaceStyle == .dark {
            backgroundGradient.colors = [
                UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1).cgColor,
                UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1).cgColor
            ]
            controlsCard.backgroundColor = .clear
            filterPillContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            filterPillContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            filterSelectedBackgroundColor = UIColor.white.withAlphaComponent(0.18)
            filterNormalTextColor = UIColor.white.withAlphaComponent(0.76)
            filterSelectedTextColor = .white
            summaryLabel.textColor = UIColor.white.withAlphaComponent(0.78)
        } else {
            backgroundGradient.colors = [
                UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.91, green: 0.91, blue: 0.93, alpha: 1).cgColor,
                UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1).cgColor
            ]
            controlsCard.backgroundColor = .clear
            filterPillContainer.backgroundColor = UIColor.black.withAlphaComponent(0.05)
            filterPillContainer.layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
            filterSelectedBackgroundColor = UIColor.black.withAlphaComponent(0.12)
            filterNormalTextColor = UIColor.label.withAlphaComponent(0.82)
            filterSelectedTextColor = UIColor.label
            summaryLabel.textColor = UIColor.secondaryLabel.withAlphaComponent(0.9)
        }

        updateFilterButtonsAppearance()
    }

    private func setupControlsCard() {
        controlsCard.backgroundColor = .clear
        controlsCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsCard)

        filterPillContainer.layer.cornerRadius = 21
        filterPillContainer.layer.cornerCurve = .continuous
        filterPillContainer.layer.borderWidth = 1
        filterPillContainer.clipsToBounds = true
        filterPillContainer.translatesAutoresizingMaskIntoConstraints = false
        filterPillContainer.heightAnchor.constraint(equalToConstant: 42).isActive = true

        filterButtonsStack.axis = .horizontal
        filterButtonsStack.alignment = .fill
        filterButtonsStack.distribution = .fillEqually
        filterButtonsStack.spacing = 6
        filterButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        filterPillContainer.addSubview(filterButtonsStack)
        NSLayoutConstraint.activate([
            filterButtonsStack.leadingAnchor.constraint(equalTo: filterPillContainer.leadingAnchor, constant: 4),
            filterButtonsStack.trailingAnchor.constraint(equalTo: filterPillContainer.trailingAnchor, constant: -4),
            filterButtonsStack.topAnchor.constraint(equalTo: filterPillContainer.topAnchor, constant: 4),
            filterButtonsStack.bottomAnchor.constraint(equalTo: filterPillContainer.bottomAnchor, constant: -4)
        ])

        buildFilterButtons()

        summaryLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [filterPillContainer, summaryLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        controlsCard.addSubview(stack)

        NSLayoutConstraint.activate([
            controlsCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            controlsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            controlsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: controlsCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: controlsCard.trailingAnchor),
            stack.topAnchor.constraint(equalTo: controlsCard.topAnchor),
            stack.bottomAnchor.constraint(equalTo: controlsCard.bottomAnchor)
        ])

        updateBackgroundStyle()
    }

    private func buildFilterButtons() {
        filterButtons.forEach { $0.removeFromSuperview() }
        filterButtons.removeAll()

        for filter in NotificationFilter.allCases {
            let button = UIButton(type: .system)
            button.tag = filter.rawValue
            button.setTitle(filter.title, for: .normal)
            button.layer.cornerRadius = 16
            button.layer.cornerCurve = .continuous
            button.layer.masksToBounds = true
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            filterButtonsStack.addArrangedSubview(button)
            filterButtons.append(button)
        }
    }

    private func updateFilterButtonsAppearance() {
        for button in filterButtons {
            let isSelected = button.tag == selectedFilter.rawValue
            button.backgroundColor = isSelected ? filterSelectedBackgroundColor : .clear
            button.setTitleColor(isSelected ? filterSelectedTextColor : filterNormalTextColor, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 11, weight: isSelected ? .bold : .semibold)
        }
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 148
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationCardCell.self, forCellReuseIdentifier: NotificationCardCell.reuseId)
        view.addSubview(tableView)

        emptyStateLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: controlsCard.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func applyFilter(animated: Bool) {
        allItems = rawNotifications.map(parseNotification)
        filteredItems = allItems.filter { selectedFilter.matches($0) }

        updateFilterButtonsAppearance()
        summaryLabel.text = summaryText(totalCount: allItems.count, filteredCount: filteredItems.count)
        emptyStateLabel.text = selectedFilter.emptyStateText
        emptyStateLabel.isHidden = !filteredItems.isEmpty

        if animated {
            UIView.transition(with: tableView, duration: 0.2, options: .transitionCrossDissolve) {
                self.tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }

    private func summaryText(totalCount: Int, filteredCount: Int) -> String {
        if selectedFilter == .all {
            return "\(totalCount) \(pluralNotifications(totalCount))"
        }
        return "\(filteredCount) в фильтре • \(totalCount) всего"
    }

    private func pluralNotifications(_ count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100

        if mod10 == 1 && mod100 != 11 { return "уведомление" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "уведомления" }
        return "уведомлений"
    }

    @objc private func filterButtonTapped(_ sender: UIButton) {
        selectedFilter = NotificationFilter(rawValue: sender.tag) ?? .all
        applyFilter(animated: true)
    }

    private func parseNotification(_ text: String) -> NotificationCardItem {
        let lines = text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let status = lines.first ?? "Уведомление"
        let lowerStatus = status.lowercased()

        let isInvitation = lowerStatus.contains("приглаш")
        let isFinal = lowerStatus.contains("итог")
        let isPreliminary = lowerStatus.contains("предвар")

        let fallbackTitle = lines.count > 1 ? lines[1] : "Без названия"
        let testTitle = value(after: "Тест:", from: lines) ?? fallbackTitle
        let reviewer: String
        if isInvitation {
            reviewer = value(after: "От:", from: lines)
                ?? value(after: "От кого:", from: lines)
                ?? value(after: "Преподаватель:", from: lines)
                ?? value(after: "Проверено:", from: lines)
                ?? "Преподаватель"
        } else {
            reviewer = value(after: "Проверено:", from: lines) ?? "Система"
        }
        let score = scoreFromNotification(text)

        return NotificationCardItem(
            status: status,
            testTitle: testTitle,
            reviewer: reviewer,
            score: score,
            isFinal: isFinal,
            isInvitation: isInvitation,
            isPreliminary: isPreliminary
        )
    }

    private func value(after prefix: String, from lines: [String]) -> String? {
        guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else { return nil }
        return line.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func scoreFromNotification(_ text: String) -> Int? {
        let pattern = #"Ваш балл:\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: (text as NSString).length)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges >= 2 else { return nil }
        let value = (text as NSString).substring(with: match.range(at: 1))
        return Int(value)
    }
}

extension NotificationsScreenViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NotificationCardCell.reuseId,
            for: indexPath
        ) as? NotificationCardCell else {
            return UITableViewCell()
        }
        cell.configure(with: filteredItems[indexPath.row])
        return cell
    }
}

private final class NotificationCardCell: UITableViewCell {
    static let reuseId = "NotificationCardCell"

    private let shadowContainer = UIView()
    private let container = UIView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let tintOverlay = UIView()
    private let accentLine = UIView()
    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let badgeLabel = UILabel()
    private let titleLabel = UILabel()
    private let reviewerLabel = UILabel()
    private let scoreLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowContainer.layer.shadowPath = UIBezierPath(
            roundedRect: shadowContainer.bounds,
            cornerRadius: 16
        ).cgPath
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        shadowContainer.layer.cornerRadius = 16
        shadowContainer.layer.cornerCurve = .continuous
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowContainer.layer.shadowRadius = 14
        shadowContainer.layer.shadowOpacity = 0.16
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowContainer)

        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.masksToBounds = true
        container.backgroundColor = UIColor { trait in
            if trait.userInterfaceStyle == .dark {
                return UIColor(red: 0.17, green: 0.17, blue: 0.20, alpha: 0.52)
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 0.90)
            }
        }
        container.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.addSubview(container)

        blur.layer.cornerRadius = 16
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blur)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tintOverlay)

        accentLine.layer.cornerRadius = 2
        accentLine.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(accentLine)

        iconWrap.layer.cornerRadius = 15
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconWrap.widthAnchor.constraint(equalToConstant: 30),
            iconWrap.heightAnchor.constraint(equalToConstant: 30)
        ])

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor)
        ])

        badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badgeLabel.heightAnchor.constraint(equalToConstant: 18),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2

        reviewerLabel.font = .systemFont(ofSize: 13, weight: .medium)
        reviewerLabel.textColor = .secondaryLabel
        reviewerLabel.numberOfLines = 2

        scoreLabel.font = .systemFont(ofSize: 14, weight: .bold)

        let headerRow = UIStackView(arrangedSubviews: [iconWrap, badgeLabel, UIView()])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [titleLabel, reviewerLabel, scoreLabel])
        textStack.axis = .vertical
        textStack.spacing = 5

        let stack = UIStackView(arrangedSubviews: [headerRow, textStack])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            shadowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            shadowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            shadowContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shadowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            container.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            container.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            container.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            tintOverlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tintOverlay.topAnchor.constraint(equalTo: container.topAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            accentLine.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            accentLine.topAnchor.constraint(equalTo: container.topAnchor),
            accentLine.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            accentLine.widthAnchor.constraint(equalToConstant: 4),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    func configure(with data: NotificationCardItem) {
        let accent = accentColor(for: data)
        let isDark = traitCollection.userInterfaceStyle == .dark

        container.layer.borderColor = accent.withAlphaComponent(0.28).cgColor
        accentLine.backgroundColor = accent
        iconWrap.backgroundColor = accent.withAlphaComponent(0.16)
        iconView.image = UIImage(systemName: iconName(for: data))
        iconView.tintColor = accent
        tintOverlay.backgroundColor = accent.withAlphaComponent(data.isInvitation ? 0.09 : 0.05)
        shadowContainer.layer.shadowOpacity = isDark ? 0.28 : 0.14

        badgeLabel.text = badgeTitle(for: data)
        badgeLabel.textColor = accent
        badgeLabel.backgroundColor = accent.withAlphaComponent(0.14)

        titleLabel.text = data.testTitle
        scoreLabel.textColor = accent

        if data.isInvitation {
            reviewerLabel.text = "Пригл. от: \(data.reviewer)"
            scoreLabel.text = nil
            scoreLabel.isHidden = true
        } else {
            reviewerLabel.text = "Проверено: \(data.reviewer)"
            scoreLabel.text = data.score.map { "Балл: \($0)" } ?? "Балл: —"
            scoreLabel.isHidden = false
        }
    }

    private func iconName(for data: NotificationCardItem) -> String {
        if data.isInvitation { return "paperplane.fill" }
        if data.isFinal { return "checkmark.seal.fill" }
        if data.isPreliminary { return "sparkles" }
        return "bell.fill"
    }

    private func badgeTitle(for data: NotificationCardItem) -> String {
        if data.isInvitation { return "Пригл." }
        if data.isFinal { return "Итоговая" }
        if data.isPreliminary { return "Предварительная" }
        return data.status
    }

    private func accentColor(for data: NotificationCardItem) -> UIColor {
        if data.isInvitation { return UIColor(red: 0.16, green: 0.52, blue: 0.98, alpha: 1) }
        if let score = data.score {
            if score >= 320 { return UIColor(red: 0.08, green: 0.60, blue: 0.34, alpha: 1) }
            if score >= 200 { return UIColor(red: 0.87, green: 0.53, blue: 0.05, alpha: 1) }
            return UIColor(red: 0.78, green: 0.23, blue: 0.20, alpha: 1)
        }
        if data.isFinal { return .systemGreen }
        if data.isPreliminary { return UIColor(red: 0.78, green: 0.23, blue: 0.20, alpha: 1) }
        return UIColor(red: 0.44, green: 0.44, blue: 0.47, alpha: 1)
    }
}
