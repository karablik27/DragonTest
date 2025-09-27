//
//  ProfileViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

import UIKit
import Firebase

final class ProfileViewController: UIViewController {
    
    
    // MARK: - Data
    private var currentUser: User?
    
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
    
    // MARK: - Notifications
    private var notifications: [String] = []
    private var processedResultIds = Set<String>()
    private var teacherNotifiedResultIds = Set<String>()
    private var didEmitInitialTests = false
    private var didEmitInitialResults = false
    
    // MARK: - Stats Data
    private var dragonsCount = 0
    private var excellentStudentsCount = 0
    private var studentTestsCount = 0
    private var teacherTestsCount = 0
    private var studentTeachersCount = 0
    private var teacherStudentsCount = 0
    private var studentAverageScore = 0.0
    private var teacherStudentsAverageScore = 0.0
    
    // MARK: - Calendar Data
    private var isWeekView = false  // false = месяц, true = неделя
    private var currentDate = Date()
    private var studentActivityDates = Set<String>()  // Даты активности студента (формат "yyyy-MM-dd")
    private var teacherActivityDates = Set<String>()  // Даты создания тестов учителя
    private var calendarCollectionView: UICollectionView?
    
    // MARK: - Firebase Listeners
    private var dragonsListener: ListenerRegistration?
    private var testsListener: ListenerRegistration?
    private var resultsListener: ListenerRegistration?
    private var studentTestsListener: ListenerRegistration?
    private var teacherTestsListener: ListenerRegistration?
    private var studentTeachersListener: ListenerRegistration?
    private var teacherStudentsListener: ListenerRegistration?
    private var studentScoreListener: ListenerRegistration?
    private var teacherScoreListener: ListenerRegistration?
    private var studentActivityListener: ListenerRegistration?
    private var teacherActivityListener: ListenerRegistration?
    
    // MARK: - Rating Data
    private var allStudentsRating: [(studentId: String, name: String, totalScore: Int, place: Int)] = []
    private var studentsListener: ListenerRegistration?
    private var usersListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addSudentsResultsSection()
        
        setupRightPanel()
        loadCurrentUser()
        
        fetchNotifications()
        fetchResultNotifications()
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
            func makeStat(icon: String, value: String, title: String) -> UIView {
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
            
            let dragons = makeStat(icon: "dragon.icon", value: "5", title: "Драконов")
            let tests = makeStat(icon: "📚", value: "12", title: "Пройдено тестов")
            let teachers = makeStat(icon: "👥", value: "3", title: "Преподавателей")
            let score = makeStat(icon: "⭐️", value: "87%", title: "Средний балл")
            
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
        let container = SettingsGlassCard(radius: 12)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        let segment = UISegmentedControl(items: ["Неделя", "Месяц"])
        segment.selectedSegmentIndex = 1
        segment.addTarget(self, action: #selector(calendarViewChanged(_:)), for: .valueChanged)
        
        // Заголовок календаря
        let calendarLabel = UILabel()
        calendarLabel.text = "Календарь активности"
        calendarLabel.font = .systemFont(ofSize: 16, weight: .medium)
        calendarLabel.textAlignment = .center
        calendarLabel.textColor = .secondaryLabel
        
        // Создаем collection view для календаря
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
    
    // MARK: - Students Results Section (подиум)
    private func addSudentsResultsSection() {
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
    
    deinit {
        dragonsListener?.remove()
        testsListener?.remove()
        resultsListener?.remove()
        studentTestsListener?.remove()
        teacherTestsListener?.remove()
        studentTeachersListener?.remove()
        teacherStudentsListener?.remove()
        studentScoreListener?.remove()
        teacherScoreListener?.remove()
        studentActivityListener?.remove()
        teacherActivityListener?.remove()
        studentsListener?.remove()
        usersListener?.remove()
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
    
    private func loadCurrentUser() {
        Task {
            do {
                let user = try await DependencyInjection.shared.currentUser.getCurrentUser()
                await MainActor.run {
                    self.currentUser = user
                    self.updateUserName()
                    self.loadUserAvatar()
                    self.loadStatsData()
                }
            } catch {
                print("Ошибка загрузки пользователя: \(error)")
            }
        }
    }
        
    private func updateUserName() {
        guard let user = currentUser else { return }
        
        if let nameLabel = nameStack.arrangedSubviews.first(where: { $0.tag == 100 }) as? UILabel {
            let name = "\(user.surname) \(user.name)".trimmingCharacters(in: .whitespacesAndNewlines)
            nameLabel.text = name.isEmpty ? "Пользователь" : name
        }
    }
    
    private func loadUserAvatar() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("profilePhoto").document(userId)

        docRef.getDocument { [weak self] snapshot, _ in
            DispatchQueue.main.async {
                if let data = snapshot?.data(),
                   let base64 = data["photoBase64"] as? String,
                   !base64.isEmpty,
                   let image = self?.decodeBase64ToImage(base64) {
                    self?.avatarImageView.image = image
                } else {
                    self?.avatarImageView.image = UIImage(named: "avatar")
                }
            }
        }
    }

    private func decodeBase64ToImage(_ base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: -Stats
    private func loadStatsData() {
        guard let user = currentUser else { return }
        
        if user.role == .student {
            loadDragonsCount()
            loadStudentTestsCount()
            loadStudentTeachersCount()
            loadStudentAverageScore()
            loadStudentActivityDates()
        } else {
            loadExcellentStudentsCount()
            loadTeacherTestsCount()
            loadTeacherStudentsCount()
            loadTeacherStudentsAverageScore()
            loadTeacherActivityDates()
        }
        
        loadRatingData()
    }
    
    private func loadDragonsCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        dragonsListener?.remove()
        
        // Устанавливаем новый слушатель
        dragonsListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .whereField("capturedDragon", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.dragonsCount = snapshot?.documents.count ?? 0
                    self?.updateStatsUI()
                }
            }
    }
    
    private func loadExcellentStudentsCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        testsListener?.remove()
        resultsListener?.remove()
        
        testsListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let testDocs = snapshot?.documents else { return }
                
                var allStudentIds = Set<String>()
                for testDoc in testDocs {
                    if let studentIds = testDoc.data()["studentIds"] as? [String] {
                        allStudentIds.formUnion(studentIds)
                    }
                }
                
                guard !allStudentIds.isEmpty else {
                    DispatchQueue.main.async {
                        self.excellentStudentsCount = 0
                        self.updateStatsUI()
                    }
                    return
                }
                
                self.resultsListener?.remove()
                self.resultsListener = db.collection("results")
                    .whereField("studentId", in: Array(allStudentIds))
                    .addSnapshotListener { [weak self] resultsSnapshot, _ in
                        guard let self = self, let resultDocs = resultsSnapshot?.documents else { return }
                        
                        // Группируем результаты по студентам
                        var studentScores: [String: [Int]] = [:]
                        for doc in resultDocs {
                            let data = doc.data()
                            guard let studentId = data["studentId"] as? String,
                                  let score = data["totalScore"] as? Int else { continue }
                            
                            if studentScores[studentId] == nil {
                                studentScores[studentId] = []
                            }
                            studentScores[studentId]?.append(score)
                        }
                        
                        // Считаем отличников (средний балл ≥ 320)
                        var excellentCount = 0
                        for (_, scores) in studentScores {
                            guard !scores.isEmpty else { continue }
                            let average = Double(scores.reduce(0, +)) / Double(scores.count)
                            if average >= 320 {
                                excellentCount += 1
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.excellentStudentsCount = excellentCount
                            self.updateStatsUI()
                        }
                    }
            }
    }
    
    private func loadStudentTestsCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        studentTestsListener?.remove()
        
        // Устанавливаем слушатель на результаты студента (пройденные тесты)
        studentTestsListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    // Считаем уникальные testId (один студент может иметь несколько попыток одного теста)
                    let uniqueTestIds = Set(snapshot?.documents.compactMap { doc in
                        doc.data()["testId"] as? String
                    } ?? [])
                    
                    self?.studentTestsCount = uniqueTestIds.count
                    self?.updateStatsUI()
                }
            }
    }
    
    private func loadTeacherTestsCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        teacherTestsListener?.remove()
        
        // Устанавливаем слушатель на тесты, созданные преподавателем
        teacherTestsListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.teacherTestsCount = snapshot?.documents.count ?? 0
                    self?.updateStatsUI()
                }
            }
    }
    
    private func loadStudentTeachersCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        studentTeachersListener?.remove()
        
        // Находим все тесты, где студент участвует, и собираем уникальных преподавателей
        studentTeachersListener = db.collection("tests")
            .whereField("studentIds", arrayContains: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    let uniqueTeacherIds = Set(snapshot?.documents.compactMap { doc in
                        doc.data()["teacherId"] as? String
                    } ?? [])
                    
                    self?.studentTeachersCount = uniqueTeacherIds.count
                    self?.updateStatsUI()
                }
            }
    }

    private func loadTeacherStudentsCount() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        teacherStudentsListener?.remove()
        
        // Находим все тесты преподавателя и собираем уникальных студентов
        teacherStudentsListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    var allStudentIds = Set<String>()
                    
                    snapshot?.documents.forEach { testDoc in
                        if let studentIds = testDoc.data()["studentIds"] as? [String] {
                            allStudentIds.formUnion(studentIds)
                        }
                    }
                    
                    self?.teacherStudentsCount = allStudentIds.count
                    self?.updateStatsUI()
                }
            }
    }
    
    private func loadStudentAverageScore() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        studentScoreListener?.remove()
        
        // Слушаем результаты студента для подсчета среднего балла
        studentScoreListener = db.collection("results")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    guard let docs = snapshot?.documents, !docs.isEmpty else {
                        self?.studentAverageScore = 0.0
                        self?.updateStatsUI()
                        return
                    }
                    
                    let totalScore = docs.reduce(0) { sum, doc in
                        let score = doc.data()["totalScore"] as? Int ?? 0
                        return sum + score
                    }
                    
                    let averageScore = Double(totalScore) / Double(docs.count)
                    // Переводим в проценты (400 баллов = 100%)
                    self?.studentAverageScore = min(100.0, max(0.0, (averageScore / 400.0) * 100.0))
                    self?.updateStatsUI()
                }
            }
    }

    private func loadTeacherStudentsAverageScore() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        // Удаляем старый слушатель если есть
        teacherScoreListener?.remove()
        
        // Сначала находим всех студентов преподавателя
        teacherScoreListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let testDocs = snapshot?.documents else { return }
                
                var allStudentIds = Set<String>()
                for testDoc in testDocs {
                    if let studentIds = testDoc.data()["studentIds"] as? [String] {
                        allStudentIds.formUnion(studentIds)
                    }
                }
                
                guard !allStudentIds.isEmpty else {
                    DispatchQueue.main.async {
                        self.teacherStudentsAverageScore = 0.0
                        self.updateStatsUI()
                    }
                    return
                }
                
                // Получаем результаты всех студентов
                db.collection("results")
                    .whereField("studentId", in: Array(allStudentIds))
                    .getDocuments { snapshot, _ in
                        DispatchQueue.main.async {
                            guard let resultDocs = snapshot?.documents, !resultDocs.isEmpty else {
                                self.teacherStudentsAverageScore = 0.0
                                self.updateStatsUI()
                                return
                            }
                            
                            // Группируем результаты по студентам и считаем средний балл каждого
                            var studentScores: [String: [Int]] = [:]
                            for doc in resultDocs {
                                let data = doc.data()
                                guard let studentId = data["studentId"] as? String,
                                      let score = data["totalScore"] as? Int else { continue }
                                
                                if studentScores[studentId] == nil {
                                    studentScores[studentId] = []
                                }
                                studentScores[studentId]?.append(score)
                            }
                            
                            // Считаем средний балл каждого студента
                            var allAverages: [Double] = []
                            for (_, scores) in studentScores {
                                guard !scores.isEmpty else { continue }
                                let average = Double(scores.reduce(0, +)) / Double(scores.count)
                                allAverages.append(average)
                            }
                            
                            // Общий средний балл всех студентов
                            let overallAverage = allAverages.isEmpty ? 0.0 : allAverages.reduce(0, +) / Double(allAverages.count)
                            
                            // Переводим в проценты (400 баллов = 100%)
                            self.teacherStudentsAverageScore = min(100.0, max(0.0, (overallAverage / 400.0) * 100.0))
                            self.updateStatsUI()
                        }
                    }
            }
    }
    
    private func loadStudentActivityDates() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        studentActivityListener?.remove()
        
        studentActivityListener = db.collection("attempts")
            .whereField("studentId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    var dates = Set<String>()
                    
                    snapshot?.documents.forEach { doc in
                        let data = doc.data()
                        if let timestamp = data["submittedAt"] as? Timestamp {
                            let date = timestamp.dateValue()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            dates.insert(formatter.string(from: date))
                        }
                    }
                    
                    self?.studentActivityDates = dates
                    self?.calendarCollectionView?.reloadData()
                }
            }
    }

    private func loadTeacherActivityDates() {
        guard let userId = DependencyInjection.shared.currentUser.userId else { return }
        let db = Firestore.firestore()
        
        teacherActivityListener?.remove()
        
        teacherActivityListener = db.collection("tests")
            .whereField("teacherId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    var dates = Set<String>()
                    
                    snapshot?.documents.forEach { doc in
                        let data = doc.data()
                        if let timestamp = data["time"] as? Timestamp {
                            let date = timestamp.dateValue()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            dates.insert(formatter.string(from: date))
                        }
                    }
                    
                    self?.teacherActivityDates = dates
                    self?.calendarCollectionView?.reloadData()
                }
            }
    }
    

    private func loadRatingData() {
        let db = Firestore.firestore()
        
        studentsListener?.remove()
        
        // Общий рейтинг по ВСЕМ тестам - только результаты с teacherComment
        studentsListener = db.collection("results")
            .whereField("teacherComment", isGreaterThan: "")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let docs = snapshot?.documents else { return }
                
                // Общий рейтинг - суммируем все баллы по всем тестам
                var studentTotalScores: [String: Int] = [:]
                
                for doc in docs {
                    let data = doc.data()
                    guard let studentId = data["studentId"] as? String,
                          let score = data["totalScore"] as? Int else { continue }
                    
                    studentTotalScores[studentId] = (studentTotalScores[studentId] ?? 0) + score
                }
                
                self.processStudentScores(studentTotalScores)
            }
    }

    private func processStudentScores(_ studentScores: [String: Int]) {
        guard !studentScores.isEmpty else {
            DispatchQueue.main.async {
                self.allStudentsRating = []
                self.updateRatingDisplay()
            }
            return
        }
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var studentsWithNames: [(studentId: String, name: String, totalScore: Int, avatar: UIImage?)] = []
        
        for (studentId, score) in studentScores {
            group.enter()
            
            // Загружаем данные пользователя
            db.collection("users").document(studentId).getDocument { doc, _ in
                guard let data = doc?.data() else {
                    group.leave()
                    return
                }
                
                let name = data["name"] as? String ?? ""
                let surname = data["surname"] as? String ?? ""
                let lastname = data["lastname"] as? String ?? ""
                
                let displayName = self.formatStudentName(name: name, surname: surname, lastname: lastname)
                
                // Загружаем аватарку
                db.collection("profilePhoto").document(studentId).getDocument { photoDoc, _ in
                    defer { group.leave() }
                    
                    var avatar: UIImage?
                    if let photoData = photoDoc?.data(),
                       let base64 = photoData["photoBase64"] as? String,
                       !base64.isEmpty,
                       let image = self.decodeBase64ToImage(base64) {
                        avatar = image
                    } else {
                        avatar = UIImage(named: "avatar")
                    }
                    
                    studentsWithNames.append((studentId: studentId, name: displayName, totalScore: score, avatar: avatar))
                }
            }
        }
        
        group.notify(queue: .main) {
            // Сортируем по баллам (по убыванию)
            let sorted = studentsWithNames.sorted { $0.totalScore > $1.totalScore }
            
            // Добавляем места (без аватарки в структуре данных, но сохраняем в кэше)
            self.allStudentsRating = sorted.enumerated().map { index, student in
                (studentId: student.studentId, name: student.name, totalScore: student.totalScore, place: index + 1)
            }
            
            // Сохраняем аватарки отдельно
            var avatarCache: [String: UIImage] = [:]
            for student in sorted {
                if let avatar = student.avatar {
                    avatarCache[student.studentId] = avatar
                }
            }
            self.updateRatingDisplay(avatars: avatarCache)
        }
    }

    private func formatStudentName(name: String, surname: String, lastname: String) -> String {
        let s = surname.trimmingCharacters(in: .whitespacesAndNewlines)
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = lastname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var initials: [String] = []
        if let first = n.first { initials.append("\(first).") }
        if let first = l.first { initials.append("\(first).") }
        
        if s.isEmpty && initials.isEmpty { return "Студент" }
        if s.isEmpty { return initials.joined(separator: " ") }
        if initials.isEmpty { return s }
        
        return "\(s) \(initials.joined(separator: " "))"
    }

    private func updateRatingDisplay(avatars: [String: UIImage] = [:]) {
        guard let container = contentStack.arrangedSubviews.last as? SettingsGlassCard else { return }
        
        // Находим подиум
        func findPodiumStack(in view: UIView) -> UIStackView? {
            if let stack = view as? UIStackView,
               stack.axis == .horizontal,
               stack.arrangedSubviews.count == 3 {
                return stack
            }
            for subview in view.subviews {
                if let found = findPodiumStack(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        guard let podiumStack = findPodiumStack(in: container) else { return }
        
        // Обновляем подиум (топ-3)
        let topThree = Array(allStudentsRating.prefix(3))
        
        for (index, podiumView) in podiumStack.arrangedSubviews.enumerated() {
            let place = index == 0 ? 2 : (index == 1 ? 1 : 3) // Порядок: 2-1-3
            let actualIndex = place - 1
            
            if actualIndex < topThree.count {
                let student = topThree[actualIndex]
                let avatar = avatars[student.studentId]
                updatePodiumView(podiumView, with: student, avatar: avatar)
            } else {
                updatePodiumView(podiumView, with: (studentId: "", name: "—", totalScore: 0, place: place), avatar: nil)
            }
        }
    }

    private func updatePodiumView(_ view: UIView, with student: (studentId: String, name: String, totalScore: Int, place: Int), avatar: UIImage?) {
        func findLabels(in view: UIView) -> (name: UILabel?, score: UILabel?, avatar: UIImageView?) {
            var nameLabel: UILabel?
            var scoreLabel: UILabel?
            var avatarView: UIImageView?
            
            func searchLabels(in v: UIView) {
                if let label = v as? UILabel {
                    // Ищем лейбл имени по размеру шрифта (14pt)
                    if label.font?.pointSize == 14 {
                        nameLabel = label
                    }
                    // Ищем лейбл счета по размеру шрифта (12pt)
                    else if label.font?.pointSize == 12 {
                        scoreLabel = label
                    }
                } else if let imageView = v as? UIImageView,
                          imageView.layer.cornerRadius == 30 { // Аватарка сверху подиума
                    avatarView = imageView
                }
                for subview in v.subviews {
                    searchLabels(in: subview)
                }
            }
            
            searchLabels(in: view)
            return (nameLabel, scoreLabel, avatarView)
        }
        
        let (nameLabel, scoreLabel, avatarView) = findLabels(in: view)
        
        // Разделяем имя на фамилию и инициалы
        let nameComponents = student.name.components(separatedBy: " ")
        let surname = nameComponents.first ?? ""
        let initials = nameComponents.dropFirst().joined(separator: " ")
        
        // Устанавливаем текст в две строки
        nameLabel?.text = "\(surname)\n\(initials)"
        nameLabel?.numberOfLines = 2
        nameLabel?.textAlignment = .center
        nameLabel?.textColor = .black // Меняем цвет на черный
        nameLabel?.font = .systemFont(ofSize: 12, weight: .medium) // Уменьшаем размер шрифта
        
        scoreLabel?.text = "\(student.totalScore)"
        scoreLabel?.textColor = .black // Меняем цвет на черный
        
        // Устанавливаем аватарку
        if let avatar = avatar {
            avatarView?.image = avatar
        } else {
            avatarView?.image = UIImage(named: "avatar")
        }
    }

    
    private func updateStatsUI() {
        // Найдем контейнер со статистикой
        guard let gridStack = contentStack.arrangedSubviews.first as? UIStackView,
              let firstRow = gridStack.arrangedSubviews.first as? UIStackView,
              let secondRow = gridStack.arrangedSubviews.count > 1 ? gridStack.arrangedSubviews[1] as? UIStackView : nil else { return }
        
        // Получаем карточки
        let firstCard = firstRow.arrangedSubviews.first
        let secondCard = firstRow.arrangedSubviews.count > 1 ? firstRow.arrangedSubviews[1] : nil
        
        // Найдем лейбл со значением (большая цифра)
        func findValueLabel(in view: UIView) -> UILabel? {
            if let label = view as? UILabel,
               label.font?.pointSize == 20,
               label.font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true {
                return label
            }
            for subview in view.subviews {
                if let found = findValueLabel(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        // Найдем лейбл с заголовком
        func findTitleLabel(in view: UIView) -> UILabel? {
            if let label = view as? UILabel,
               label.font?.pointSize == 14,
               label.textColor == .secondaryLabel {
                return label
            }
            for subview in view.subviews {
                if let found = findTitleLabel(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        guard let user = currentUser else { return }
        
        // Обновляем первый квадратик
        if let firstCard = firstCard,
           let valueLabel = findValueLabel(in: firstCard),
           let titleLabel = findTitleLabel(in: firstCard) {
            
            if user.role == .student {
                valueLabel.text = "\(dragonsCount)"
                titleLabel.text = "Драконов"
            } else {
                valueLabel.text = "\(excellentStudentsCount)"
                titleLabel.text = "Отличников"
            }
        }
        
        // Обновляем второй квадратик
        if let secondCard = secondCard,
           let valueLabel = findValueLabel(in: secondCard),
           let titleLabel = findTitleLabel(in: secondCard) {
            
            if user.role == .student {
                valueLabel.text = "\(studentTestsCount)"
                titleLabel.text = "Пройдено тестов"
            } else {
                valueLabel.text = "\(teacherTestsCount)"
                titleLabel.text = "Тестов создано"
            }
        }
        
        // Обновляем третий квадратик
        if let thirdCard = secondRow.arrangedSubviews.first,
           let valueLabel = findValueLabel(in: thirdCard),
           let titleLabel = findTitleLabel(in: thirdCard) {
            
            if user.role == .student {
                valueLabel.text = "\(studentTeachersCount)"
                titleLabel.text = "Преподавателей"
            } else {
                valueLabel.text = "\(teacherStudentsCount)"
                titleLabel.text = "Студентов"
            }
        }
        
        // Обновляем четвертый квадратик
        if let fourthCard = secondRow.arrangedSubviews.count > 1 ? secondRow.arrangedSubviews[1] : nil,
           let valueLabel = findValueLabel(in: fourthCard),
           let titleLabel = findTitleLabel(in: fourthCard) {
            
            if user.role == .student {
                valueLabel.text = String(format: "%.0f%%", studentAverageScore)
                titleLabel.text = "Средний балл"
            } else {
                valueLabel.text = String(format: "%.0f%%", teacherStudentsAverageScore)
                titleLabel.text = "Средний балл учеников"
            }
        }
        
        // Обновляем иконки в зависимости от роли
        if let firstCard = firstCard {
            updateIcons(in: firstCard, for: user.role, position: 1)
        }
        if let secondCard = secondCard {
            updateIcons(in: secondCard, for: user.role, position: 2)
        }
        if let thirdCard = secondRow.arrangedSubviews.first {
            updateIcons(in: thirdCard, for: user.role, position: 3)
        }
        if let fourthCard = secondRow.arrangedSubviews.count > 1 ? secondRow.arrangedSubviews[1] : nil {
            updateIcons(in: fourthCard, for: user.role, position: 4)
        }
    }
    
    private func updateIcons(in view: UIView?, for role: Role, position: Int) {
        guard let view = view else { return }
        
        // Ищем UIImageView с иконкой - первый UIImageView в stack
        func findIconView(in v: UIView) -> UIImageView? {
            // Ищем UIStackView с вертикальной осью
            if let stack = v as? UIStackView, stack.axis == .vertical {
                // Берем первый элемент (иконку)
                if let firstView = stack.arrangedSubviews.first as? UIImageView {
                    return firstView
                }
            }
            for subview in v.subviews {
                if let found = findIconView(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        guard let iconView = findIconView(in: view) else { 
            
            return 
        }
        
        
        
        // Определяем иконку по позиции квадратика
        let iconName: String
        switch position {
        case 1: // Первый квадратик
            iconName = role == .student ? "flame.fill" : "trophy.fill"
        case 2: // Второй квадратик
            iconName = role == .student ? "book.fill" : "doc.text.fill"
        case 3: // Третий квадратик
            iconName = role == .student ? "person.2.fill" : "graduationcap.fill"
        case 4: // Четвертый квадратик
            iconName = role == .student ? "star.fill" : "chart.bar.fill"
        default:
            iconName = "questionmark"
        }
        
        // Для всех SF Symbols используем одинаковый подход
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
        let image = UIImage(systemName: iconName, withConfiguration: config)
        iconView.image = image
        iconView.tintColor = .black
        
    }
    
    @objc func didTapBell() { showPanel() }
    
    @objc private func calendarViewChanged(_ sender: UISegmentedControl) {
        isWeekView = (sender.selectedSegmentIndex == 0)
        calendarCollectionView?.reloadData()
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

// MARK: - Calendar Collection View
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    private func getDaysToShow() -> [Date] {
        let calendar = Calendar.current
        
        if isWeekView {
            // Показываем текущую неделю
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start ?? currentDate
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        } else {
            // Показываем текущий месяц
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
        
        // Проверяем активность
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let hasActivity: Bool
        if let user = currentUser, user.role == .student {
            hasActivity = studentActivityDates.contains(dateString)
        } else {
            hasActivity = teacherActivityDates.contains(dateString)
        }
        
        cell.configure(hasActivity: hasActivity, isToday: Calendar.current.isDateInToday(date))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        let availableWidth = width - 16 // padding
        let columns: CGFloat = isWeekView ? 7 : 7
        let cellWidth = (availableWidth - (columns - 1) * 2) / columns
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - Calendar Cell
class CalendarDayCell: UICollectionViewCell {
    let dayLabel = UILabel()
    private let activityIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        layer.cornerRadius = 8
        
        dayLabel.textAlignment = .center
        dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        activityIndicator.backgroundColor = .systemBlue
        activityIndicator.layer.cornerRadius = 3
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(dayLabel)
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            activityIndicator.widthAnchor.constraint(equalToConstant: 6),
            activityIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func configure(hasActivity: Bool, isToday: Bool) {
        activityIndicator.isHidden = !hasActivity
        
        if isToday {
            // Сегодняшний день - яркий синий фон
            backgroundColor = UIColor.systemBlue
            dayLabel.textColor = .white
            dayLabel.font = .systemFont(ofSize: 14, weight: .bold)
            layer.borderWidth = 0
        } else if hasActivity {
            // День с активностью - светло-зеленый фон
            backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
            layer.borderWidth = 1
            layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            // Обычный день - легкий белый фон с границей
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
            dayLabel.textColor = .label
            dayLabel.font = .systemFont(ofSize: 14, weight: .medium)
            layer.borderWidth = 0.5
            layer.borderColor = UIColor.separator.cgColor
        }
        
        if hasActivity {
            if isToday {
                activityIndicator.backgroundColor = .white
            } else {
                activityIndicator.backgroundColor = .systemGreen
            }
        }
    }
}
