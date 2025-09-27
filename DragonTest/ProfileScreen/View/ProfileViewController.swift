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

    // MARK: - UI (правая панель)
    private let dimView = UIView()
    private let panelView = UIView()
    private let panelGrabber = UIView()
    private var panelLeadingConstraint: NSLayoutConstraint!
    private let panelWidth: CGFloat = 320
    private var panelIsVisible = false
    private var panelPanStartX: CGFloat = 0
    private let panelScrollView = UIScrollView()
    private let panelListStack = UIStackView()

    // MARK: - Local state (только для UI)
    private var notifications: [String] = []
    private var isWeekView = false
    private var currentDate = Date()
    private var studentActivityDates = Set<String>()
    private var teacherActivityDates = Set<String>()
    private var calendarCollectionView: UICollectionView?
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addSudentsResultsSection()
        setupRightPanel()

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

    // Статистика (как была)
    func addStatsSection() {
        func makeStat(icon: String, value: String, title: String) -> UIView {
            let container = SettingsGlassCard(radius: 12)

            let avatar = UIImageView(image: UIImage(named: icon))
            avatar.contentMode = .scaleAspectFit
            avatar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 25),
                avatar.heightAnchor.constraint(equalToConstant: 25)
            ])

            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
            valueLabel.textColor = .label

            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .secondaryLabel

            let stack = UIStackView(arrangedSubviews: [avatar, valueLabel, titleLabel])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 100)
            ])

            return container
        }

        let dragons  = makeStat(icon: "dragon.icon", value: "5",   title: "Драконов")
        let tests    = makeStat(icon: "📚",         value: "12",  title: "Пройдено тестов")
        let teachers = makeStat(icon: "👥",         value: "3",   title: "Преподавателей")
        let score    = makeStat(icon: "⭐️",         value: "87%", title: "Средний балл")

        let row1 = UIStackView(arrangedSubviews: [dragons, tests])
        row1.axis = .horizontal
        row1.spacing = 12
        row1.distribution = .fillEqually

        let row2 = UIStackView(arrangedSubviews: [teachers, score])
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .fillEqually

        let grid = UIStackView(arrangedSubviews: [row1, row2])
        grid.axis = .vertical
        grid.spacing = 12

        contentStack.addArrangedSubview(grid)
    }

    // Календарь
    func addCalendarSection() {
        let container = SettingsGlassCard(radius: 12)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 300).isActive = true

        let segment = UISegmentedControl(items: ["Неделя", "Месяц"])
        segment.selectedSegmentIndex = 1
        segment.addTarget(self, action: #selector(calendarViewChanged(_:)), for: .valueChanged)

        let calendarLabel = UILabel()
        calendarLabel.text = "Календарь активности"
        calendarLabel.font = .systemFont(ofSize: 16, weight: .medium)
        calendarLabel.textAlignment = .center
        calendarLabel.textColor = .secondaryLabel

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        collectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "DayCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        self.calendarCollectionView = collectionView

        let stack = UIStackView(arrangedSubviews: [segment, calendarLabel, collectionView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(container)
    }

    // Подиум
    func addSudentsResultsSection() {
        let container = SettingsGlassCard(radius: 16)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 450).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "Рейтинг прохождения тестов"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        func makeStudentView(place: Int, name: String, score: String, imageName: String) -> UIView {
            let column = UIView()

            let avatar = UIImageView(image: UIImage(named: imageName))
            avatar.contentMode = .scaleAspectFill
            avatar.layer.cornerRadius = 30
            avatar.clipsToBounds = true
            avatar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 60),
                avatar.heightAnchor.constraint(equalToConstant: 60)
            ])

            let kind: DragonKind = {
                switch place {
                case 1: return .red
                case 2: return .green
                default: return .blue
                }
            }()

            let podium = UIView()
            podium.layer.cornerRadius = 12
            podium.clipsToBounds = true
            podium.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                podium.heightAnchor.constraint(equalToConstant: place == 1 ? 140 : 100),
                podium.widthAnchor.constraint(equalToConstant: 105)
            ])

            let gradient = GradientBackground.attach(to: podium, colors: kind.gradientColors)
            DispatchQueue.main.async { gradient.frame = podium.bounds }

            switch place {
            case 1:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(red: 0.99, green: 0.84, blue: 0.33, alpha: 1).cgColor
            case 2:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            case 3:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(red: 0.80, green: 0.55, blue: 0.30, alpha: 1).cgColor
            default: break
            }

            let placeLabel = UILabel()
            placeLabel.text = {
                switch place {
                case 1: return "1 🏆"
                case 2: return "2 🥈"
                case 3: return "3 🥉"
                default: return "\(place)"
                }
            }()
            placeLabel.font = .systemFont(ofSize: 20, weight: .bold)
            placeLabel.textColor = .white
            placeLabel.textAlignment = .center

            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
            nameLabel.textColor = .white
            nameLabel.textAlignment = .center

            let scoreLabel = UILabel()
            scoreLabel.text = score
            scoreLabel.font = .systemFont(ofSize: 12)
            scoreLabel.textColor = .white
            scoreLabel.textAlignment = .center

            let vstack = UIStackView(arrangedSubviews: [placeLabel, nameLabel, scoreLabel])
            vstack.axis = .vertical
            vstack.alignment = .center
            vstack.spacing = 4
            vstack.translatesAutoresizingMaskIntoConstraints = false

            podium.addSubview(vstack)
            NSLayoutConstraint.activate([
                vstack.centerXAnchor.constraint(equalTo: podium.centerXAnchor),
                vstack.centerYAnchor.constraint(equalTo: podium.centerYAnchor)
            ])

            let stack = UIStackView(arrangedSubviews: [avatar, podium])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 8

            column.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: column.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: column.trailingAnchor),
                stack.topAnchor.constraint(equalTo: column.topAnchor),
                stack.bottomAnchor.constraint(equalTo: column.bottomAnchor)
            ])

            return column
        }

        let first  = makeStudentView(place: 1, name: "Maxwell", score: "7,120", imageName: "teacher1")
        let second = makeStudentView(place: 2, name: "Camelia", score: "6,500", imageName: "teacher2")
        let third  = makeStudentView(place: 3, name: "Wilson", score: "4,800", imageName: "teacher3")

        let podiumStack = UIStackView(arrangedSubviews: [second, first, third])
        podiumStack.axis = .horizontal
        podiumStack.alignment = .bottom
        podiumStack.distribution = .equalSpacing
        podiumStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [titleLabel, podiumStack])
        mainStack.axis = .vertical
        mainStack.spacing = 32

        container.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(container)
    }

    // Правая панель
    func setupRightPanel() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hidePanel)))

        panelView.backgroundColor = .systemBackground
        panelView.layer.cornerRadius = 20
        panelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        panelView.layer.shadowColor = UIColor.black.cgColor
        panelView.layer.shadowOpacity = 0.15
        panelView.layer.shadowOffset = CGSize(width: -2, height: 0)
        panelView.layer.shadowRadius = 8
        panelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panelView)

        panelLeadingConstraint = panelView.leadingAnchor.constraint(equalTo: view.trailingAnchor)
        NSLayoutConstraint.activate([
            panelLeadingConstraint,
            panelView.topAnchor.constraint(equalTo: view.topAnchor),
            panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panelView.widthAnchor.constraint(equalToConstant: panelWidth)
        ])

        panelGrabber.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.3)
        panelGrabber.layer.cornerRadius = 2

        let title = UILabel()
        title.text = "Уведомления"
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Очистить", for: .normal)
        clearBtn.addTarget(self, action: #selector(clearAllNotifications), for: .touchUpInside)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Закрыть", for: .normal)
        closeBtn.addTarget(self, action: #selector(hidePanel), for: .touchUpInside)

        let header = UIStackView(arrangedSubviews: [title, clearBtn, UIView(), closeBtn])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 9

        panelListStack.axis = .vertical
        panelListStack.spacing = 12
        panelListStack.translatesAutoresizingMaskIntoConstraints = false

        panelScrollView.alwaysBounceVertical = true
        panelScrollView.showsVerticalScrollIndicator = true
        panelScrollView.translatesAutoresizingMaskIntoConstraints = false
        panelScrollView.addSubview(panelListStack)

        NSLayoutConstraint.activate([
            panelListStack.leadingAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.leadingAnchor),
            panelListStack.trailingAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.trailingAnchor),
            panelListStack.topAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.topAnchor),
            panelListStack.bottomAnchor.constraint(equalTo: panelScrollView.contentLayoutGuide.bottomAnchor),
            panelListStack.widthAnchor.constraint(equalTo: panelScrollView.frameLayoutGuide.widthAnchor)
        ])

        let panelStack = UIStackView(arrangedSubviews: [panelGrabber, header, panelScrollView])
        panelStack.axis = .vertical
        panelStack.spacing = 16
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(panelStack)

        NSLayoutConstraint.activate([
            panelGrabber.heightAnchor.constraint(equalToConstant: 4),
            panelGrabber.widthAnchor.constraint(equalToConstant: 36),

            panelStack.topAnchor.constraint(equalTo: panelView.safeAreaLayoutGuide.topAnchor, constant: 12),
            panelStack.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            panelStack.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            panelStack.bottomAnchor.constraint(equalTo: panelView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        panelView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanelPan(_:))))
    }

    // MARK: - Panel helpers
    func showPanel(animated: Bool = true) {
        guard !panelIsVisible else { return }
        panelIsVisible = true
        panelLeadingConstraint.constant = -panelWidth
        let animations = {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 1
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) { animations() }
        } else {
            animations()
        }
    }

    @objc func hidePanel() {
        guard panelIsVisible else { return }
        panelIsVisible = false
        panelLeadingConstraint.constant = 0
        UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseIn]) {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0
        }
    }

    @objc func handlePanelPan(_ g: UIPanGestureRecognizer) {
        let translation = g.translation(in: view).x
        switch g.state {
        case .began:
            panelPanStartX = panelLeadingConstraint.constant
        case .changed:
            let next = min(0, panelPanStartX + translation)
            panelLeadingConstraint.constant = next
            let visibleRatio = 1 - abs(next) / panelWidth
            dimView.alpha = max(0, min(1, visibleRatio))
            view.layoutIfNeeded()
        case .ended, .cancelled:
            let velocityX = g.velocity(in: view).x
            let shouldClose = (velocityX > 500) || (panelLeadingConstraint.constant > -panelWidth * 0.5)
            if shouldClose { hidePanel() } else { showPanel() }
        default: break
        }
    }
}

// MARK: - Actions
private extension ProfileViewController {
    @objc func didTapBell() {
        presenter.didTapBell()
        showPanel()
    }

    @objc func clearAllNotifications() {
        // мгновенно чистим локальный UI, а затем просим презентер сбросить источник
        self.notifications.removeAll()
        updateNotificationList()
        presenter.clearNotifications()
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
        updateNotificationList()
    }

    func setStats(_ vm: ProfileStatsViewModel) {
        isStudentRole = vm.isStudent

        // Найдём грид
        guard let gridStack = contentStack.arrangedSubviews.first as? UIStackView,
              let firstRow  = gridStack.arrangedSubviews.first as? UIStackView,
              let secondRow = gridStack.arrangedSubviews.count > 1 ? gridStack.arrangedSubviews[1] as? UIStackView : nil
        else { return }

        let firstCard  = firstRow.arrangedSubviews.first
        let secondCard = firstRow.arrangedSubviews.count > 1 ? firstRow.arrangedSubviews[1] : nil

        func findValueLabel(in view: UIView) -> UILabel? {
            if let label = view as? UILabel,
               label.font?.pointSize == 20,
               label.font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true { return label }
            for sub in view.subviews { if let f = findValueLabel(in: sub) { return f } }
            return nil
        }

        func findTitleLabel(in view: UIView) -> UILabel? {
            if let label = view as? UILabel,
               label.font?.pointSize == 14,
               label.textColor == .secondaryLabel { return label }
            for sub in view.subviews { if let f = findTitleLabel(in: sub) { return f } }
            return nil
        }

        // 1
        if let c = firstCard,
           let v = findValueLabel(in: c),
           let t = findTitleLabel(in: c) {
            if vm.isStudent {
                v.text = "\(vm.dragonsCount)"
                t.text = "Драконов"
            } else {
                v.text = "\(vm.excellentStudentsCount)"
                t.text = "Отличников"
            }
            updateIcons(in: c, forStudent: vm.isStudent, position: 1)
        }

        // 2
        if let c = secondCard,
           let v = findValueLabel(in: c),
           let t = findTitleLabel(in: c) {
            if vm.isStudent {
                v.text = "\(vm.studentTestsCount)"
                t.text = "Пройдено тестов"
            } else {
                v.text = "\(vm.teacherTestsCount)"
                t.text = "Тестов создано"
            }
            updateIcons(in: c, forStudent: vm.isStudent, position: 2)
        }

        // 3
        if let c = secondRow.arrangedSubviews.first,
           let v = findValueLabel(in: c),
           let t = findTitleLabel(in: c) {
            if vm.isStudent {
                v.text = "\(vm.studentTeachersCount)"
                t.text = "Преподавателей"
            } else {
                v.text = "\(vm.teacherStudentsCount)"
                t.text = "Студентов"
            }
            updateIcons(in: c, forStudent: vm.isStudent, position: 3)
        }

        // 4
        if let c = secondRow.arrangedSubviews.count > 1 ? secondRow.arrangedSubviews[1] : nil,
           let v = findValueLabel(in: c),
           let t = findTitleLabel(in: c) {
            if vm.isStudent {
                v.text = String(format: "%.0f%%", vm.studentAveragePercent)
                t.text = "Средний балл"
            } else {
                v.text = String(format: "%.0f%%", vm.teacherStudentsAveragePercent)
                t.text = "Средний балл учеников"
            }
            updateIcons(in: c, forStudent: vm.isStudent, position: 4)
        }
    }

    func setActivityDates(student: Set<String>, teacher: Set<String>) {
        self.studentActivityDates = student
        self.teacherActivityDates = teacher
    }

    func reloadCalendar() { calendarCollectionView?.reloadData() }

    func setRating(_ items: [RatingItem], avatars: [String: UIImage]) {
        guard let container = contentStack.arrangedSubviews.last as? SettingsGlassCard else { return }

        func findPodiumStack(in view: UIView) -> UIStackView? {
            if let stack = view as? UIStackView,
               stack.axis == .horizontal,
               stack.arrangedSubviews.count == 3 { return stack }
            for sub in view.subviews { if let f = findPodiumStack(in: sub) { return f } }
            return nil
        }

        guard let podiumStack = findPodiumStack(in: container) else { return }

        let topThree = Array(items.prefix(3)) // уже с place
        for (index, podiumView) in podiumStack.arrangedSubviews.enumerated() {
            let place = index == 0 ? 2 : (index == 1 ? 1 : 3) // порядок 2-1-3
            if let student = topThree.first(where: { $0.place == place }) {
                updatePodiumView(podiumView,
                                 name: student.displayName,
                                 score: "\(student.totalScore)",
                                 avatar: avatars[student.studentId])
            } else {
                updatePodiumView(podiumView, name: "—", score: "0", avatar: UIImage(named: "avatar"))
            }
        }
    }

    func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Helpers (icons, notifications, podium)
private extension ProfileViewController {

    func updateIcons(in view: UIView?, forStudent: Bool, position: Int) {
        guard let view = view else { return }

        func findIconView(in v: UIView) -> UIImageView? {
            if let stack = v as? UIStackView, stack.axis == .vertical {
                if let first = stack.arrangedSubviews.first as? UIImageView { return first }
            }
            for sub in v.subviews { if let f = findIconView(in: sub) { return f } }
            return nil
        }

        guard let iconView = findIconView(in: view) else { return }

        let iconName: String
        switch position {
        case 1: iconName = forStudent ? "flame.fill" : "trophy.fill"
        case 2: iconName = forStudent ? "book.fill" : "doc.text.fill"
        case 3: iconName = forStudent ? "person.2.fill" : "graduationcap.fill"
        case 4: iconName = forStudent ? "star.fill" : "chart.bar.fill"
        default: iconName = "questionmark"
        }

        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        iconView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconView.tintColor = .black
    }

    func updatePodiumView(_ view: UIView, name: String, score: String, avatar: UIImage?) {
        func findTargets(in v: UIView) -> (name: UILabel?, score: UILabel?, avatar: UIImageView?) {
            var nameLabel: UILabel?
            var scoreLabel: UILabel?
            var avatarView: UIImageView?
            func scan(_ node: UIView) {
                if let l = node as? UILabel {
                    if l.font?.pointSize == 14 { nameLabel = l }
                    else if l.font?.pointSize == 12 { scoreLabel = l }
                } else if let img = node as? UIImageView, img.layer.cornerRadius == 30 {
                    avatarView = img
                }
                node.subviews.forEach { scan($0) }
            }
            scan(v)
            return (nameLabel, scoreLabel, avatarView)
        }

        let (nameLabel, scoreLabel, avatarView) = findTargets(in: view)

        // Разбиваем "Фамилия И.О." на две строки (как было)
        let comps = name.components(separatedBy: " ")
        let surname = comps.first ?? ""
        let initials = comps.dropFirst().joined(separator: " ")
        nameLabel?.text = "\(surname)\n\(initials)"
        nameLabel?.numberOfLines = 2
        nameLabel?.textAlignment = .center
        nameLabel?.textColor = .black
        nameLabel?.font = .systemFont(ofSize: 12, weight: .medium)

        scoreLabel?.text = score
        scoreLabel?.textColor = .black

        avatarView?.image = avatar ?? UIImage(named: "avatar")
    }

    func updateNotificationList() {
        panelListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        notifications.forEach { notification in
            let container = UIView()
            let score = scoreFromNotification(notification)
            container.backgroundColor = backgroundColor(for: score)
            container.layer.cornerRadius = 12
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.5
            container.layer.shadowOffset = CGSize(width: 0, height: 3)
            container.layer.shadowRadius = 6

            let icon = UIImageView(image: UIImage(systemName: "book.fill"))
            icon.tintColor = .systemBlue
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
            icon.widthAnchor.constraint(equalToConstant: 40).isActive = true

            let label = UILabel()
            label.text = notification
            label.font = .systemFont(ofSize: 16, weight: .semibold)
            label.textColor = .label
            label.numberOfLines = 0

            let stack = UIStackView(arrangedSubviews: [icon, label])
            stack.axis = .horizontal
            stack.spacing = 10
            stack.alignment = .center
            stack.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
            ])

            panelListStack.addArrangedSubview(container)
        }
    }

    func scoreFromNotification(_ text: String) -> Int? {
        let pattern = #"Ваш балл:\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: (text as NSString).length)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges >= 2 else { return nil }
        let nsText = text as NSString
        let valueString = nsText.substring(with: match.range(at: 1))
        return Int(valueString)
    }

    func backgroundColor(for score: Int?) -> UIColor {
        guard let score = score else { return UIColor(white: 0.95, alpha: 1) }
        if score < 160 {
            return UIColor(red: 1.0, green: 0.90, blue: 0.90, alpha: 1.0)
        } else if score < 300 {
            return UIColor(red: 1.0, green: 0.97, blue: 0.85, alpha: 1.0)
        } else if score <= 400 {
            return UIColor(red: 0.90, green: 1.0, blue: 0.90, alpha: 1.0)
        } else {
            return UIColor(white: 0.95, alpha: 1)
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
        let availableWidth = width - 16
        let columns: CGFloat = 7
        let cellWidth = (availableWidth - (columns - 1) * 2) / columns
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
