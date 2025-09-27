//
//  ProfileViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

import UIKit
import Firebase

final class ProfileViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return testNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return testNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        testTextField?.text = testNames[row]
    }
    
    
    // MARK: - Data
    private var testNames: [String] = []
    private var pickerView: UIPickerView?
    private weak var testTextField: UITextField?
    
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
    
    // MARK: - Localization References
    private weak var welcomeLabel: UILabel?
    private weak var nameLabel: UILabel?
    private weak var dragonsStatTitle: UILabel?
    private weak var testsStatTitle: UILabel?
    private weak var teachersStatTitle: UILabel?
    private weak var averageScoreStatTitle: UILabel?
    private weak var calendarTitleLabel: UILabel?
    private weak var ratingTitleLabel: UILabel?
    private weak var periodSegment: UISegmentedControl?
    private weak var testPicker: UITextField?
    private weak var searchField: UITextField?
    private weak var notificationsTitle: UILabel?
    private weak var closeButton: UIButton?
    
    // MARK: - Notifications
    private var notifications: [String] = []
    private var processedResultIds = Set<String>()
    private var teacherNotifiedResultIds = Set<String>()
    private var didEmitInitialTests = false
    private var didEmitInitialResults = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addSudentsResultsSection()
        
        setupRightPanel()
        
        fetchNotifications()
        fetchResultNotifications()
        setupAutoLocalization()
    }
    
    // MARK: - Localization
    override func updateLocalization() {
        super.updateLocalization()
        
        welcomeLabel?.text = "profile.welcome".localized
        nameLabel?.text = currentUser?.name ?? "profile.username".localized
        dragonsStatTitle?.text = "profile.stat_dragons".localized
        testsStatTitle?.text = "profile.stat_tests".localized
        teachersStatTitle?.text = "profile.stat_teachers".localized
        averageScoreStatTitle?.text = "profile.stat_average_score".localized
        calendarTitleLabel?.text = "profile.calendar".localized
        ratingTitleLabel?.text = "profile.rating_title".localized
        notificationsTitle?.text = "profile.notifications".localized
        closeButton?.setTitle("profile.close".localized, for: .normal)
        
        // Update segment control
        periodSegment?.setTitle("profile.period_week".localized, forSegmentAt: 0)
        periodSegment?.setTitle("profile.period_month".localized, forSegmentAt: 1)
        
        // Update placeholders
        testPicker?.placeholder = "profile.test_placeholder".localized
        searchField?.placeholder = "profile.search_placeholder".localized
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }
    
    private func setupBackground() {
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
    
    // MARK: - Header
    private func setupHeader() {
        // Убираем старый фон
        headerView.backgroundColor = .clear
        headerView.layer.cornerRadius = 32
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.masksToBounds = false

        // Glass-эффект
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

        // Тень
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.2
        headerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        headerView.layer.shadowRadius = 12

        // Лейблы
        let welcomeLabel = UILabel()
        welcomeLabel.text = "profile.welcome".localized
        welcomeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        welcomeLabel.textColor = .secondaryLabel
        self.welcomeLabel = welcomeLabel

        let nameLabel = UILabel()
        nameLabel.text = "profile.username".localized
        self.nameLabel = nameLabel
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label

        nameStack.axis = .vertical
        nameStack.spacing = 2
        nameStack.addArrangedSubview(welcomeLabel)
        nameStack.addArrangedSubview(nameLabel)

        // Кнопка-колокол
        let bellImage = UIImage(systemName: "bell")
        bellButton.setImage(bellImage, for: .normal)
        bellButton.tintColor = .label
        bellButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bellButton.widthAnchor.constraint(equalToConstant: 28),
            bellButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        bellButton.addTarget(self, action: #selector(didTapBell), for: .touchUpInside)

        // Аватар
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

    
    // MARK: - Layout
    private func setupLayout() {
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
    
    // MARK: - Stats Section
    private func addStatsSection() {
            func makeStat(icon: String, value: String, title: String, titleRef: inout UILabel?) -> UIView {
                let container = SettingsGlassCard(radius: 12)   // ✅ используем стеклянный card
                
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
                titleRef = titleLabel  // Сохраняем ссылку
                
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
            
                          let dragons = makeStat(icon: "dragon.icon", value: "5", title: "profile.stat_dragons".localized, titleRef: &dragonsStatTitle)
              let tests = makeStat(icon: "📚", value: "12", title: "profile.stat_tests".localized, titleRef: &testsStatTitle)
              let teachers = makeStat(icon: "👑", value: "3", title: "profile.stat_teachers".localized, titleRef: &teachersStatTitle)
              let score = makeStat(icon: "⭐️", value: "87%", title: "profile.stat_average_score".localized, titleRef: &averageScoreStatTitle)
            
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
    
    // MARK: - Calendar Section
    private func addCalendarSection() {
            let container = SettingsGlassCard(radius: 12) // ✅ стеклянный card
            container.translatesAutoresizingMaskIntoConstraints = false
            container.heightAnchor.constraint(equalToConstant: 260).isActive = true
            
            let segment = UISegmentedControl(items: ["profile.period_week".localized, "profile.period_month".localized])
        self.periodSegment = segment
            segment.selectedSegmentIndex = 1
            
            let calendarLabel = UILabel()
            calendarLabel.text = "profile.calendar".localized
        self.calendarTitleLabel = calendarLabel
            calendarLabel.font = .systemFont(ofSize: 16, weight: .medium)
            calendarLabel.textAlignment = .center
            calendarLabel.textColor = .secondaryLabel
            
            let stack = UIStackView(arrangedSubviews: [segment, calendarLabel])
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
    
    // MARK: - Students Results Section (подиум)
    private func addSudentsResultsSection() {
        let container = SettingsGlassCard(radius: 16)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 450).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "profile.rating_title".localized
        self.ratingTitleLabel = titleLabel
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        testNames = ["Коллоквиум №1", "Коллоквиум №2", "Итоговый тест", "Практика iOS"]

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        self.pickerView = picker

        // Поле выбора теста (glass)
        let testField = SettingsGlassTextField(placeholder: "profile.test_placeholder".localized)
        testField.textField.inputView = picker
        self.testTextField = testField.textField
        self.testPicker = testField.textField

        // Поле поиска (glass)
        let searchField = SettingsGlassTextField(placeholder: "profile.search_placeholder".localized)
        self.searchField = searchField.textField
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        searchIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        // Встраиваем иконку внутрь textField
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: 20))
        iconContainer.addSubview(searchIcon)
        searchIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor).isActive = true
        searchIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor).isActive = true
        searchField.textField.leftView = iconContainer
        searchField.textField.leftViewMode = .always

        let filterStack = UIStackView(arrangedSubviews: [titleLabel, testField, searchField])
        filterStack.axis = .vertical
        filterStack.spacing = 16

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

        let mainStack = UIStackView(arrangedSubviews: [filterStack, podiumStack])
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


    
    private func fetchNotifications() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }

        let db = Firestore.firestore()
        db.collection("tests")
            .whereField("studentIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else { return }

                // Первый снимок: заполняем UI, но не шлём пуш
                if !self.didEmitInitialTests {
                    self.didEmitInitialTests = true
                    let docs = snapshot.documents
                    guard !docs.isEmpty else { return }

                    let items = docs.map { doc -> String in
                        let data = doc.data()
                        let testTitle = data["title"] as? String ?? "Тест"
                        return "Вы приглашены в тест:\n\(testTitle)"
                    }
                    self.prependNotifications(items)
                    DispatchQueue.main.async { self.updateNotificationList() }
                    return
                }

                // Дальше — только реальные добавления
                let added = snapshot.documentChanges.filter { $0.type == .added }
                guard !added.isEmpty else { return }

                let newItems = added.map { change -> String in
                    let data = change.document.data()
                    let testTitle = data["title"] as? String ?? "Тест"
                    return "Вы приглашены в тест:\n\(testTitle)"
                }

                self.prependNotifications(newItems)
                DispatchQueue.main.async {
                    self.updateNotificationList()
                    NotificationCenter.default.post(name: .newTestNotification, object: nil)
                }
            }
    }
    
    private func fetchTestNameByTestId(testId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        guard !testId.isEmpty else { completion(nil); return }

        // Сначала попробуем как documentId
        db.collection("tests").document(testId).getDocument { doc, _ in
            if let doc = doc, doc.exists {
                let title = doc.data()?["title"] as? String
                completion(title)
            } else {
                // Fallback: поле testId в документе
                db.collection("tests")
                    .whereField("testId", isEqualTo: testId)
                    .getDocuments { snapshot, _ in
                        let title = snapshot?.documents.first?.data()["title"] as? String
                        completion(title)
                    }
            }
        }
    }
    
    // ФИО → "Фамилия И.О."
    private func shortTeacherName(name: String?, surname: String?, lastname: String?) -> String {
        let s = (surname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let n = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let l = (lastname ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var initials: [String] = []
        if let first = n.first { initials.append("\(first).") }
        if let first = l.first { initials.append("\(first).") }
        if s.isEmpty, initials.isEmpty { return "Преподаватель" }
        if s.isEmpty { return initials.joined(separator: " ") }
        if initials.isEmpty { return s }
        return "\(s) \(initials.joined(separator: " "))"
    }
    
    // По testId → tests.teacherId → users.{name,surname,lastname} → "Фамилия И.О."
    private func fetchTeacherShortNameByTestId(testId: String, completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        guard !testId.isEmpty else { completion(nil); return }
        
        func build(from teacherId: String) {
            db.collection("users").document(teacherId).getDocument { doc, _ in
                guard let doc = doc, doc.exists, let data = doc.data() else {
                    completion(nil); return
                }
                let name = data["name"] as? String
                let surname = data["surname"] as? String
                let lastname = data["lastname"] as? String
                completion(self.shortTeacherName(name: name, surname: surname, lastname: lastname))
            }
        }
        
        // tests может быть как documentId == testId, так и с полем testId
        db.collection("tests").document(testId).getDocument { doc, _ in
            if let doc = doc, doc.exists, let data = doc.data(), let teacherId = data["teacherId"] as? String {
                build(from: teacherId)
            } else {
                db.collection("tests")
                    .whereField("testId", isEqualTo: testId)
                    .limit(to: 1)
                    .getDocuments { snap, _ in
                        guard let testData = snap?.documents.first?.data(),
                              let teacherId = testData["teacherId"] as? String else {
                            completion(nil); return
                        }
                        build(from: teacherId)
                    }
            }
        }
    }
    
    private func prependNotifications(_ items: [String]) {
        guard !items.isEmpty else { return }
        for item in items.reversed() {
            notifications.insert(item, at: 0)
        }
    }
    
    private func fetchResultNotifications() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        
        let db = Firestore.firestore()
        db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let snapshot = snapshot else { return }
                
                // Первый снимок: только в UI, без пуша
                if !self.didEmitInitialResults {
                    self.didEmitInitialResults = true
                    
                    let docs = snapshot.documents
                    guard !docs.isEmpty else { return }
                    
                    let group = DispatchGroup()
                    var built: [String] = []
                    
                    for doc in docs {
                        let resultId = doc.documentID
                        if self.processedResultIds.contains(resultId) { continue }
                        self.processedResultIds.insert(resultId)
                        
                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)
                        
                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            if hasTeacher {
                                // Нужна фамилия и инициалы
                                self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                    let teacher = teacherShort ?? "Преподаватель"
                                    let text = "Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)"
                                    built.append(text)
                                    self.teacherNotifiedResultIds.insert(resultId)
                                    group.leave()
                                }
                            } else {
                                // Предварительные + название теста
                                let text = "Предварительная оценка\nТест: \(title)\nПроверено: Автоматическая проверка\nВаш балл: \(testScore)"
                                built.append(text)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.updateNotificationList()
                    }
                    return
                }
                
                // Добавленные результаты
                let added = snapshot.documentChanges.filter { $0.type == .added }
                if !added.isEmpty {
                    let group = DispatchGroup()
                    var built: [String] = []
                    
                    for change in added {
                        let doc = change.document
                        let resultId = doc.documentID
                        if self.processedResultIds.contains(resultId) { continue }
                        self.processedResultIds.insert(resultId)
                        
                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)
                        
                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            if hasTeacher {
                                self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                    let teacher = teacherShort ?? "Преподаватель"
                                    let text = "Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)"
                                    built.append(text)
                                    self.teacherNotifiedResultIds.insert(resultId)
                                    group.leave()
                                }
                            } else {
                                let text = "Предварительная оценка\nТест: \(title)\nПроверено: Автоматическая проверка\nВаш балл: \(testScore)"
                                built.append(text)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.updateNotificationList()
                        NotificationCenter.default.post(name: .newResultNotification, object: nil)
                    }
                }
                
                // Изменённые результаты: ловим момент появления teacherComment
                let modified = snapshot.documentChanges.filter { $0.type == .modified }
                if !modified.isEmpty {
                    let group = DispatchGroup()
                    var built: [String] = []
                    
                    for change in modified {
                        let doc = change.document
                        let resultId = doc.documentID
                        
                        let data = doc.data()
                        let testScore = data["totalScore"] as? Int ?? 0
                        let testId = data["testId"] as? String ?? ""
                        let teacherComment = data["teacherComment"] as? String
                        let hasTeacher = (teacherComment?.isEmpty == false)
                        
                        // Уведомляем итоговую оценку только один раз для каждого результата
                        guard hasTeacher, !self.teacherNotifiedResultIds.contains(resultId) else { continue }
                        self.teacherNotifiedResultIds.insert(resultId)
                        
                        group.enter()
                        self.fetchTestNameByTestId(testId: testId) { testTitle in
                            let title = testTitle ?? "Не найдено!"
                            self.fetchTeacherShortNameByTestId(testId: testId) { teacherShort in
                                let teacher = teacherShort ?? "Преподаватель"
                                let text = "Итоговая оценка\nТест: \(title)\nПроверено: \(teacher)\nВаш балл: \(testScore)"
                                built.append(text)
                                group.leave()
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        guard !built.isEmpty else { return }
                        self.prependNotifications(built)
                        self.updateNotificationList()
                        NotificationCenter.default.post(name: .newResultNotification, object: nil)
                    }
                }
            }
    }
    
    private func updateNotificationList() {
        // Очищаем текущие элементы
        panelListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Добавляем карточки уведомлений
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

    // Извлекает балл из строки уведомления вида "Ваш балл: N"
    private func scoreFromNotification(_ text: String) -> Int? {
        let pattern = #"Ваш балл:\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: (text as NSString).length)
        guard let match = regex.firstMatch(in: text, options: [], range: range), match.numberOfRanges >= 2 else { return nil }
        let nsText = text as NSString
        let valueString = nsText.substring(with: match.range(at: 1))
        return Int(valueString)
    }

    // Возвращает мягкие цвета в зависимости от диапазона баллов
    private func backgroundColor(for score: Int?) -> UIColor {
        guard let score = score else {
            return UIColor(white: 0.95, alpha: 1)
        }
        if score < 160 {
            // лёгкий красный
            return UIColor(red: 1.0, green: 0.90, blue: 0.90, alpha: 1.0)
        } else if score < 300 {
            // лёгкий жёлтый
            return UIColor(red: 1.0, green: 0.97, blue: 0.85, alpha: 1.0)
        } else if score <= 400 {
            // лёгкий зелёный
            return UIColor(red: 0.90, green: 1.0, blue: 0.90, alpha: 1.0)
        } else {
            // на всякий случай — нейтральный
            return UIColor(white: 0.95, alpha: 1)
        }
    }
}

// MARK: - Правая панель уведомлений
private extension ProfileViewController {
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
        title.text = "profile.notifications".localized
        self.notificationsTitle = title
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Очистить", for: .normal)
        clearBtn.addTarget(self, action: #selector(clearAllNotifications), for: .touchUpInside)

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("profile.close".localized, for: .normal)
        self.closeButton = closeBtn
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
    
    @objc func didTapBell() { showPanel() }
    
    private func showPanel(animated: Bool = true) {
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
    
    @objc private func clearAllNotifications() {
        notifications.removeAll()
        processedResultIds.removeAll()
        teacherNotifiedResultIds.removeAll()
        didEmitInitialTests = false
        didEmitInitialResults = false
        updateNotificationList()
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

extension Notification.Name {
    static let newTestNotification = Notification.Name("newTestNotification")
    static let newResultNotification = Notification.Name("newResultNotification")
}
