//
//  ProfileViewController.swift
//  DragonTest
//
//  Created by Лазарева Александра on 23.09.2025.
//

import UIKit
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController {

    // MARK: - DI / MVP
    private let presenter: ProfilePresenterProtocol

    // MARK: - UI (основной экран)
    private let headerView = UIView()
    private let nameStack = UIStackView()
    private let bellButton = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // MARK: - Local state (только для UI)
    private var notifications: [String] = []
    private weak var notificationsScreen: NotificationsScreenViewController?
    private var isWeekView = false
    private var currentDate = Date()
    private var studentActivityDates = Set<String>()
    private var teacherActivityDates = Set<String>()
    private var calendarCollectionView: UICollectionView?
    private var statCards: [Int: ProfileStatCardView] = [:]
    private var podiumViewsByPlace: [Int: ProfilePodiumCardView] = [:]
    private var hasInitialStatsLoaded = false
    private var hasInitialRatingLoaded = false
    private var didNotifyInitialDataReady = false
    private var shouldGateInitialContent = false
    private var initialDataReadyHandler: (() -> Void)?
    private let initialLoadingOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let initialLoadingIndicator = UIActivityIndicatorView(style: .large)
    private let initialLoadingLabel = UILabel()
    private static let averageScoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    private var isStudentRole = true  // выставляется из setStats(_:), нужен для календаря и иконок

    // MARK: - Init
    init(presenter: ProfilePresenterProtocol = ProfilePresenter()) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.presenter = ProfilePresenter()
        super.init(coder: coder)
    }

    func prepareForInitialDataGate() {
        shouldGateInitialContent = true
        if isViewLoaded {
            setInitialLoadingOverlayVisible(true, animated: false)
        }
    }

    func setInitialDataReadyHandler(_ handler: @escaping () -> Void) {
        initialDataReadyHandler = handler
        if didNotifyInitialDataReady {
            handler()
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addSudentsResultsSection()
        setupInitialLoadingOverlay()
        if shouldGateInitialContent {
            setInitialLoadingOverlayVisible(true, animated: false)
        }

        presenter.attach(view: self)
        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }
}

// MARK: - UI building
private extension ProfileViewController {

    func setupBackground() {
        view.layer.sublayers?
            .filter { $0.name == "backgroundGradient" }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = "backgroundGradient"
        gradient.colors = [
            UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1).cgColor,
            UIColor(red: 206/255, green: 204/255, blue: 195/255, alpha: 1).cgColor,
            UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.25, 0.65, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.frame      = view.bounds
        gradient.zPosition  = -1000
        view.layer.insertSublayer(gradient, at: 0)
    }

    func setupHeader() {
        headerView.backgroundColor = .clear
        headerView.layer.cornerRadius = 32
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.masksToBounds = false

        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 32
        blurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        blurView.clipsToBounds = true

        headerView.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: headerView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])

        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.2
        headerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        headerView.layer.shadowRadius = 12

        let welcomeLabel = UILabel()
        welcomeLabel.text = "Добро пожаловать,"
        welcomeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        welcomeLabel.textColor = .secondaryLabel

        let nameLabel = UILabel()
        nameLabel.text = "Username"
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.tag = 100

        nameStack.axis = .vertical
        nameStack.spacing = 2
        nameStack.addArrangedSubview(welcomeLabel)
        nameStack.addArrangedSubview(nameLabel)

        let bellImage = UIImage(systemName: "bell")
        bellButton.setImage(bellImage, for: .normal)
        bellButton.tintColor = .label
        bellButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bellButton.widthAnchor.constraint(equalToConstant: 28),
            bellButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        bellButton.addTarget(self, action: #selector(didTapBell), for: .touchUpInside)

        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        let rightStack = UIStackView(arrangedSubviews: [bellButton, avatarImageView])
        rightStack.axis = .horizontal
        rightStack.spacing = 12
        rightStack.alignment = .center

        let mainStack = UIStackView(arrangedSubviews: [nameStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.distribution = .equalSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: -40),
            mainStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
    }

    func setupLayout() {
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    func setupInitialLoadingOverlay() {
        initialLoadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        initialLoadingOverlay.isHidden = true
        initialLoadingOverlay.alpha = 0
        view.addSubview(initialLoadingOverlay)
        NSLayoutConstraint.activate([
            initialLoadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            initialLoadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            initialLoadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            initialLoadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let loadingCard = UIView()
        loadingCard.translatesAutoresizingMaskIntoConstraints = false
        loadingCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.55)
        loadingCard.layer.cornerRadius = 16
        loadingCard.layer.cornerCurve = .continuous
        loadingCard.layer.borderWidth = 1
        loadingCard.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor
        initialLoadingOverlay.contentView.addSubview(loadingCard)

        initialLoadingIndicator.hidesWhenStopped = false
        initialLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        initialLoadingIndicator.startAnimating()

        initialLoadingLabel.text = "Загрузка профиля..."
        initialLoadingLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        initialLoadingLabel.textColor = .label
        initialLoadingLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [initialLoadingIndicator, initialLoadingLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        loadingCard.addSubview(stack)

        NSLayoutConstraint.activate([
            loadingCard.centerXAnchor.constraint(equalTo: initialLoadingOverlay.centerXAnchor),
            loadingCard.centerYAnchor.constraint(equalTo: initialLoadingOverlay.centerYAnchor),
            loadingCard.widthAnchor.constraint(equalToConstant: 190),
            loadingCard.heightAnchor.constraint(equalToConstant: 140),

            stack.centerXAnchor.constraint(equalTo: loadingCard.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: loadingCard.centerYAnchor)
        ])
    }

    func setInitialLoadingOverlayVisible(_ visible: Bool, animated: Bool) {
        guard shouldGateInitialContent else { return }
        if visible {
            initialLoadingOverlay.isHidden = false
        }

        let changes = {
            self.initialLoadingOverlay.alpha = visible ? 1 : 0
        }

        let complete: (Bool) -> Void = { _ in
            if !visible {
                self.initialLoadingOverlay.isHidden = true
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: changes, completion: complete)
        } else {
            changes()
            complete(true)
        }
    }

    func markInitialDataLoaded(stats: Bool = false, rating: Bool = false) {
        if stats { hasInitialStatsLoaded = true }
        if rating { hasInitialRatingLoaded = true }

        guard hasInitialStatsLoaded, hasInitialRatingLoaded else { return }
        guard !didNotifyInitialDataReady else { return }

        didNotifyInitialDataReady = true
        setInitialLoadingOverlayVisible(false, animated: true)
        initialDataReadyHandler?()
    }

    func formatAverageScore(fromPercent percent: Double) -> String {
        let clampedPercent = max(0, min(100, percent))
        let score = clampedPercent / 10.0
        if let localized = Self.averageScoreFormatter.string(from: NSNumber(value: score)) {
            return localized
        }
        return String(format: "%.1f", score)
    }

    func makeSectionHeader(iconName: String, title: String, subtitle: String) -> UIStackView {
        let iconWrap = UIView()
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.32)
        iconWrap.layer.cornerRadius = 14
        iconWrap.layer.cornerCurve = .continuous
        NSLayoutConstraint.activate([
            iconWrap.widthAnchor.constraint(equalToConstant: 28),
            iconWrap.heightAnchor.constraint(equalToConstant: 28)
        ])

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = .label
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor)
        ])

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 1

        let header = UIStackView(arrangedSubviews: [iconWrap, textStack, UIView()])
        header.axis = .horizontal
        header.spacing = 10
        header.alignment = .center
        return header
    }

    // Статистика
    func addStatsSection() {
        let container = SettingsGlassCard(radius: 18)
        container.translatesAutoresizingMaskIntoConstraints = false

        let header = makeSectionHeader(
            iconName: "chart.bar.fill",
            title: "Статистика",
            subtitle: "Ключевые показатели по вашему профилю"
        )

        let first = ProfileStatCardView(accentColor: UIColor(red: 0.95, green: 0.50, blue: 0.20, alpha: 1))
        let second = ProfileStatCardView(accentColor: UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1))
        let third = ProfileStatCardView(accentColor: UIColor(red: 0.18, green: 0.66, blue: 0.44, alpha: 1))
        let fourth = ProfileStatCardView(accentColor: UIColor(red: 0.95, green: 0.75, blue: 0.16, alpha: 1))
        [first, second, third, fourth].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 106).isActive = true
        }

        statCards = [1: first, 2: second, 3: third, 4: fourth]
        first.configure(value: "0", title: "Драконов", iconName: "flame.fill")
        second.configure(value: "0", title: "Пройдено тестов", iconName: "book.closed.fill")
        third.configure(value: "0", title: "Преподавателей", iconName: "person.2.fill")
        fourth.configure(value: formatAverageScore(fromPercent: 0), title: "Средний балл", iconName: "star.fill")

        let row1 = UIStackView(arrangedSubviews: [first, second])
        row1.axis = .horizontal
        row1.spacing = 10
        row1.distribution = .fillEqually

        let row2 = UIStackView(arrangedSubviews: [third, fourth])
        row2.axis = .horizontal
        row2.spacing = 10
        row2.distribution = .fillEqually

        let grid = UIStackView(arrangedSubviews: [row1, row2])
        grid.axis = .vertical
        grid.spacing = 10

        let stack = UIStackView(arrangedSubviews: [header, grid])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        contentStack.addArrangedSubview(container)
    }

    // Календарь
    func addCalendarSection() {
        let container = SettingsGlassCard(radius: 18)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 360).isActive = true

        let header = makeSectionHeader(
            iconName: "calendar",
            title: "Календарь активности",
            subtitle: "Отслеживайте регулярность занятий"
        )

        let segment = UISegmentedControl(items: ["Неделя", "Месяц"])
        segment.selectedSegmentIndex = 1
        segment.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.9)
        segment.backgroundColor = UIColor.black.withAlphaComponent(0.10)
        segment.layer.cornerRadius = 16
        segment.layer.cornerCurve = .continuous
        segment.clipsToBounds = true
        segment.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 13, weight: .semibold)],
            for: .normal
        )
        segment.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.black
            ],
            for: .selected
        )
        segment.addTarget(self, action: #selector(calendarViewChanged(_:)), for: .valueChanged)
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.heightAnchor.constraint(equalToConstant: 34).isActive = true

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        collectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        self.calendarCollectionView = collectionView

        let collectionWrap = UIView()
        collectionWrap.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.30)
        collectionWrap.layer.cornerRadius = 16
        collectionWrap.layer.cornerCurve = .continuous
        collectionWrap.layer.borderWidth = 1
        collectionWrap.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        collectionWrap.translatesAutoresizingMaskIntoConstraints = false
        collectionWrap.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: collectionWrap.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: collectionWrap.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: collectionWrap.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: collectionWrap.bottomAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [header, segment, collectionWrap])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        contentStack.addArrangedSubview(container)
    }

    // Подиум
    func addSudentsResultsSection() {
        let container = SettingsGlassCard(radius: 18)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 390).isActive = true

        let header = makeSectionHeader(
            iconName: "trophy.fill",
            title: "Рейтинг прохождения",
            subtitle: "Лучшие результаты среди студентов"
        )

        let first = ProfilePodiumCardView(place: 1)
        let second = ProfilePodiumCardView(place: 2)
        let third = ProfilePodiumCardView(place: 3)
        [first, second, third].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        podiumViewsByPlace = [1: first, 2: second, 3: third]

        first.configure(name: "—", score: "0", avatar: nil)
        second.configure(name: "—", score: "0", avatar: nil)
        third.configure(name: "—", score: "0", avatar: nil)

        let podiumStack = UIStackView(arrangedSubviews: [second, first, third])
        podiumStack.axis = .horizontal
        podiumStack.alignment = .bottom
        podiumStack.distribution = .fillEqually
        podiumStack.spacing = 8
        podiumStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView(arrangedSubviews: [header, podiumStack])
        mainStack.axis = .vertical
        mainStack.spacing = 18

        container.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(container)
    }

}

// MARK: - Actions
private extension ProfileViewController {
    @objc func didTapBell() {
        presenter.didTapBell()

        let vc = NotificationsScreenViewController(notifications: notifications)
        vc.hidesBottomBarWhenPushed = true
        notificationsScreen = vc
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func calendarViewChanged(_ sender: UISegmentedControl) {
        isWeekView = (sender.selectedSegmentIndex == 0)
        calendarCollectionView?.reloadData()
        presenter.calendarViewChanged(isWeekView: isWeekView)
    }
}

// MARK: - ProfileViewProtocol
extension ProfileViewController: ProfileViewProtocol {
    func setWelcomeName(_ name: String) {
        if let nameLabel = nameStack.arrangedSubviews.first(where: { $0.tag == 100 }) as? UILabel {
            nameLabel.text = name.isEmpty ? "Пользователь" : name
        }
    }

    func setAvatar(_ image: UIImage) { avatarImageView.image = image }
    func setAvatarPlaceholder() { avatarImageView.image = UIImage(named: "avatar") }

    func setNotifications(_ items: [String]) {
        self.notifications = items
        notificationsScreen?.updateNotifications(items)
    }

    func setStats(_ vm: ProfileStatsViewModel) {
        isStudentRole = vm.isStudent
        if vm.isStudent {
            statCards[1]?.configure(value: "\(vm.dragonsCount)", title: "Драконов", iconName: "flame.fill")
            statCards[2]?.configure(value: "\(vm.studentTestsCount)", title: "Пройдено тестов", iconName: "book.closed.fill")
            statCards[3]?.configure(value: "\(vm.studentTeachersCount)", title: "Преподавателей", iconName: "person.2.fill")
            statCards[4]?.configure(value: formatAverageScore(fromPercent: vm.studentAveragePercent), title: "Средний балл", iconName: "star.fill")
        } else {
            statCards[1]?.configure(value: "\(vm.excellentStudentsCount)", title: "Отличников", iconName: "trophy.fill")
            statCards[2]?.configure(value: "\(vm.teacherTestsCount)", title: "Тестов создано", iconName: "doc.text.fill")
            statCards[3]?.configure(value: "\(vm.teacherStudentsCount)", title: "Студентов", iconName: "graduationcap.fill")
            statCards[4]?.configure(value: formatAverageScore(fromPercent: vm.teacherStudentsAveragePercent), title: "Средний балл учеников", iconName: "chart.bar.fill")
        }
        markInitialDataLoaded(stats: true)
    }

    func setActivityDates(student: Set<String>, teacher: Set<String>) {
        self.studentActivityDates = student
        self.teacherActivityDates = teacher
    }

    func reloadCalendar() { calendarCollectionView?.reloadData() }

    func setRating(_ items: [RatingItem], avatars: [String: UIImage]) {
        let topThree = Array(items.prefix(3))
        for place in 1...3 {
            if let student = topThree.first(where: { $0.place == place }) {
                podiumViewsByPlace[place]?.configure(
                    name: student.displayName,
                    score: "\(student.totalScore)",
                    avatar: avatars[student.studentId]
                )
            } else {
                podiumViewsByPlace[place]?.configure(
                    name: "—",
                    score: "0",
                    avatar: nil
                )
            }
        }
        markInitialDataLoaded(rating: true)
    }

    func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

private final class ProfileStatCardView: UIView {
    private let accentColor: UIColor
    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    init(accentColor: UIColor) {
        self.accentColor = accentColor
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: String, title: String, iconName: String) {
        valueLabel.text = value
        titleLabel.text = title
        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = accentColor
    }

    private func setupUI() {
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.32)

        iconWrap.backgroundColor = accentColor.withAlphaComponent(0.18)
        iconWrap.layer.cornerRadius = 12
        iconWrap.layer.cornerCurve = .continuous
        iconWrap.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconWrap.widthAnchor.constraint(equalToConstant: 28),
            iconWrap.heightAnchor.constraint(equalToConstant: 28)
        ])

        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconWrap.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor)
        ])

        valueLabel.font = .systemFont(ofSize: 30, weight: .heavy)
        valueLabel.textColor = .label
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.65

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 2

        let topRow = UIStackView(arrangedSubviews: [iconWrap, UIView()])
        topRow.axis = .horizontal

        let stack = UIStackView(arrangedSubviews: [topRow, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}

private final class ProfilePodiumCardView: UIView {
    private let place: Int
    private let placeColor: UIColor
    private let secondaryColor: UIColor
    private let pedestalHeight: CGFloat
    private let pedestalWidth: CGFloat
    private let badgeLabel = UILabel()
    private let avatarView = UIImageView()
    private let avatarPlaceholder = UIImageView()
    private let pedestal = UIView()
    private let pedestalGradient = CAGradientLayer()
    private let nameLabel = UILabel()
    private let scoreLabel = UILabel()

    init(place: Int) {
        self.place = place

        switch place {
        case 1:
            self.placeColor = UIColor(red: 0.95, green: 0.72, blue: 0.12, alpha: 1)
            self.secondaryColor = UIColor(red: 0.86, green: 0.50, blue: 0.08, alpha: 1)
            self.pedestalHeight = 170
            self.pedestalWidth = 126
        case 2:
            self.placeColor = UIColor(red: 0.66, green: 0.70, blue: 0.76, alpha: 1)
            self.secondaryColor = UIColor(red: 0.42, green: 0.46, blue: 0.53, alpha: 1)
            self.pedestalHeight = 142
            self.pedestalWidth = 118
        default:
            self.placeColor = UIColor(red: 0.77, green: 0.55, blue: 0.36, alpha: 1)
            self.secondaryColor = UIColor(red: 0.58, green: 0.39, blue: 0.24, alpha: 1)
            self.pedestalHeight = 126
            self.pedestalWidth = 112
        }

        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        pedestal.layoutIfNeeded()
        pedestalGradient.frame = pedestal.bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyTheme()
    }

    func configure(name: String, score: String, avatar: UIImage?) {
        nameLabel.text = compactDisplayName(name)
        scoreLabel.text = "Балл: \(score)"

        if name == "—" || avatar == nil {
            avatarView.image = nil
            avatarPlaceholder.isHidden = false
        } else {
            avatarView.image = avatar
            avatarPlaceholder.isHidden = true
        }
    }

    private func setupUI() {
        let badgeText: String = {
            switch place {
            case 1: return "1 место"
            case 2: return "2 место"
            default: return "3 место"
            }
        }()

        badgeLabel.text = badgeText
        badgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.cornerCurve = .continuous
        badgeLabel.clipsToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 84).isActive = true

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 30
        avatarView.layer.cornerCurve = .continuous
        avatarView.layer.borderWidth = 2
        avatarView.clipsToBounds = true
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60)
        ])

        avatarPlaceholder.image = UIImage(systemName: "person.fill")
        avatarPlaceholder.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        avatarPlaceholder.contentMode = .scaleAspectFit
        avatarPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarPlaceholder)
        NSLayoutConstraint.activate([
            avatarPlaceholder.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarPlaceholder.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        pedestal.layer.cornerRadius = 16
        pedestal.layer.cornerCurve = .continuous
        pedestal.layer.borderWidth = 1.5
        pedestal.clipsToBounds = true
        pedestal.translatesAutoresizingMaskIntoConstraints = false
        pedestal.heightAnchor.constraint(equalToConstant: pedestalHeight).isActive = true
        pedestal.widthAnchor.constraint(equalToConstant: pedestalWidth).isActive = true
        pedestalGradient.startPoint = CGPoint(x: 0, y: 0)
        pedestalGradient.endPoint = CGPoint(x: 1, y: 1)
        pedestal.layer.insertSublayer(pedestalGradient, at: 0)

        nameLabel.font = .systemFont(ofSize: 12, weight: .bold)
        nameLabel.numberOfLines = 3
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.textAlignment = .center

        scoreLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        scoreLabel.textAlignment = .center

        let pedestalText = UIStackView(arrangedSubviews: [nameLabel, scoreLabel])
        pedestalText.axis = .vertical
        pedestalText.spacing = 6
        pedestalText.translatesAutoresizingMaskIntoConstraints = false
        pedestal.addSubview(pedestalText)
        NSLayoutConstraint.activate([
            pedestalText.leadingAnchor.constraint(equalTo: pedestal.leadingAnchor, constant: 8),
            pedestalText.trailingAnchor.constraint(equalTo: pedestal.trailingAnchor, constant: -8),
            pedestalText.centerYAnchor.constraint(equalTo: pedestal.centerYAnchor)
        ])

        let stack = UIStackView(arrangedSubviews: [badgeLabel, avatarView, pedestal])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyTheme()
    }

    private func compactDisplayName(_ name: String) -> String {
        guard name != "—" else { return "—" }

        let parts = name.split(separator: " ")
        guard let firstPart = parts.first else { return name }

        var surname = String(firstPart)
        if surname.count > 11 {
            let prefix = surname.prefix(10)
            surname = "\(prefix)…"
        }

        let rest = parts.dropFirst().joined(separator: " ")
        if rest.isEmpty { return surname }
        return "\(surname)\n\(rest)"
    }

    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if isDark {
            badgeLabel.textColor = placeColor
            badgeLabel.backgroundColor = placeColor.withAlphaComponent(0.18)
            avatarView.layer.borderColor = placeColor.cgColor
            avatarView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.45)
            avatarPlaceholder.tintColor = placeColor.withAlphaComponent(0.95)
            pedestal.layer.borderColor = placeColor.withAlphaComponent(0.9).cgColor
            pedestalGradient.colors = [
                placeColor.withAlphaComponent(0.86).cgColor,
                secondaryColor.withAlphaComponent(0.92).cgColor
            ]
            nameLabel.textColor = .white
            scoreLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        } else {
            badgeLabel.textColor = placeColor.withAlphaComponent(0.95)
            badgeLabel.backgroundColor = placeColor.withAlphaComponent(0.24)
            avatarView.layer.borderColor = placeColor.withAlphaComponent(0.85).cgColor
            avatarView.backgroundColor = UIColor.white.withAlphaComponent(0.88)
            avatarPlaceholder.tintColor = placeColor.withAlphaComponent(0.85)
            pedestal.layer.borderColor = placeColor.withAlphaComponent(0.65).cgColor
            pedestalGradient.colors = pastelGradientColors()
            nameLabel.textColor = UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1)
            scoreLabel.textColor = UIColor(red: 0.24, green: 0.25, blue: 0.30, alpha: 0.92)
        }
    }

    private func pastelGradientColors() -> [CGColor] {
        switch place {
        case 1:
            return [
                UIColor(red: 1.00, green: 0.91, blue: 0.62, alpha: 1).cgColor,
                UIColor(red: 0.98, green: 0.83, blue: 0.43, alpha: 1).cgColor
            ]
        case 2:
            return [
                UIColor(red: 0.89, green: 0.92, blue: 0.97, alpha: 1).cgColor,
                UIColor(red: 0.76, green: 0.81, blue: 0.90, alpha: 1).cgColor
            ]
        default:
            return [
                UIColor(red: 0.93, green: 0.85, blue: 0.76, alpha: 1).cgColor,
                UIColor(red: 0.86, green: 0.74, blue: 0.61, alpha: 1).cgColor
            ]
        }
    }
}

// MARK: - Calendar Collection View
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private func getDaysToShow() -> [Date] {
        let calendar = Calendar.current
        if isWeekView {
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        } else {
            let startOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
            let range = calendar.range(of: .day, in: .month, for: currentDate) ?? 1..<32
            return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth) }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getDaysToShow().count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! CalendarDayCell

        let days = getDaysToShow()
        let date = days[indexPath.item]

        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        cell.dayLabel.text = formatter.string(from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let hasActivity = isStudentRole ? studentActivityDates.contains(dateString) : teacherActivityDates.contains(dateString)
        cell.configure(hasActivity: hasActivity, isToday: Calendar.current.isDateInToday(date))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let horizontalInsets: CGFloat = 20
        let spacing: CGFloat = 6
        let columns: CGFloat = 7
        let availableWidth = width - horizontalInsets
        let cellWidth = (availableWidth - (columns - 1) * spacing) / columns
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
