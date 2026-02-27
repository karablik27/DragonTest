//
//  AddTestViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 22.09.2025.
//

import UIKit
import FirebaseFirestore

final class AddTestViewController: UIViewController {

    weak var delegate: AddTestDelegate?
    private let testService: TestServiceProtocol

    // MARK: - Steps
    private enum Step { case details, mode }
    private var currentStep: Step = .details {
        didSet { updateStepUI(animated: true) }
    }

    // MARK: - State
    private var participants: [String] = []
    private var addedUsers: [User] = []
    private var allStudents: [User] = []
    private var searchResults: [User] = []
    private var currentTitle: String {
        titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let stepLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private let titleLabel = UILabel()
    private let titleField = GlassTextField(placeholder: "Введите название теста")
    private let participantsLabel = UILabel()
    private let participantField = GlassTextField(placeholder: "Поиск ученика по имени или почте")
    private let participantsHeaderRow = UIStackView()
    private let addAllStudentsButton = UIButton(type: .system)
    private let clearParticipantsButton = UIButton(type: .system)
    private let emptySearchLabel = UILabel()

    // Таблица результатов поиска
    private let searchResultsTable = UITableView(frame: .zero, style: .plain)
    private let searchGlassWrapper = GlassView(radius: 16)

    // Карточка «Ученики»
    private let participantsContainer = GlassView(radius: 20)
    private let participantsStack = UIStackView()

    private let step1Stack = UIStackView()
    private let step2Stack = UIStackView()

    // Кнопки-действия (второй шаг — круг)
    private let circleShadowWrapper = UIView()
    private let circleContainer = UIView()
    private let leftHalfButton = UIButton(type: .system)
    private let rightHalfButton = UIButton(type: .system)
    private let circleSeparator = UIView()
    private let step2HintLabel = UILabel()

    // MARK: - Init
    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false

        setupUI()
        setupActions()

        searchResultsTable.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseId)
        searchResultsTable.isHidden = false
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        configureSearchEmptyState()

        currentStep = .details
        updateNextButtonState()
        refreshParticipantsChips()
        updateParticipantsActionButtons()
        loadAllStudents()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        circleContainer.layer.cornerRadius = circleContainer.bounds.width / 2
        if #available(iOS 13.0, *) { circleContainer.layer.cornerCurve = .continuous }
    }

    // MARK: - Setup UI
    private func setupUI() {
        scrollView.backgroundColor = .clear
        scrollView.isOpaque = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.backgroundColor = .clear
        contentStack.isOpaque = false
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        // Header
        stepLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        stepLabel.textColor = .secondaryLabel
        stepLabel.textAlignment = .center

        backButton.setTitle("Назад", for: .normal)
        nextButton.setTitle("Далее", for: .normal)
        nextButton.backgroundColor = .systemBlue
        nextButton.tintColor = .white
        nextButton.layer.cornerRadius = 10
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true
        headerContainer.backgroundColor = .clear

        headerContainer.addSubview(backButton)
        headerContainer.addSubview(stepLabel)
        headerContainer.addSubview(nextButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            nextButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            stepLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            stepLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
        ])

        // Step 1
        titleLabel.text = "Название теста"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        participantsLabel.text = "Ученики"
        participantsLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        participantsHeaderRow.axis = .horizontal
        participantsHeaderRow.alignment = .center
        participantsHeaderRow.spacing = 8

        var addAllConfig = UIButton.Configuration.tinted()
        addAllConfig.title = "Добавить всех"
        addAllConfig.baseForegroundColor = .white
        addAllConfig.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.35)
        addAllConfig.cornerStyle = .medium
        addAllConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        addAllStudentsButton.configuration = addAllConfig
        addAllStudentsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

        var clearConfig = UIButton.Configuration.tinted()
        clearConfig.title = "Очистить"
        clearConfig.baseForegroundColor = .white
        clearConfig.baseBackgroundColor = UIColor.systemGray.withAlphaComponent(0.30)
        clearConfig.cornerStyle = .medium
        clearConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        clearParticipantsButton.configuration = clearConfig
        clearParticipantsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

        participantsHeaderRow.addArrangedSubview(participantsLabel)
        participantsHeaderRow.addArrangedSubview(UIView())
        participantsHeaderRow.addArrangedSubview(addAllStudentsButton)
        participantsHeaderRow.addArrangedSubview(clearParticipantsButton)

        // Таблица поиска — полностью прозрачная
        searchResultsTable.layer.cornerRadius = 12
        searchResultsTable.clipsToBounds = true
        searchResultsTable.backgroundColor = .clear
        searchResultsTable.isOpaque = false
        searchResultsTable.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        searchResultsTable.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))
        searchResultsTable.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))
        searchResultsTable.keyboardDismissMode = .onDrag

        searchGlassWrapper.addSubview(searchResultsTable)
        searchGlassWrapper.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchResultsTable.topAnchor.constraint(equalTo: searchGlassWrapper.topAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: searchGlassWrapper.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: searchGlassWrapper.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: searchGlassWrapper.bottomAnchor),
            searchGlassWrapper.heightAnchor.constraint(equalToConstant: 260)
        ])

        participantsStack.axis = .vertical
        participantsStack.spacing = 8
        participantsStack.alignment = .fill
        participantsContainer.addSubview(participantsStack)
        participantsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantsStack.topAnchor.constraint(equalTo: participantsContainer.topAnchor, constant: 12),
            participantsStack.leadingAnchor.constraint(equalTo: participantsContainer.leadingAnchor, constant: 12),
            participantsStack.trailingAnchor.constraint(equalTo: participantsContainer.trailingAnchor, constant: -12),
            participantsStack.bottomAnchor.constraint(equalTo: participantsContainer.bottomAnchor, constant: -12),
        ])

        step1Stack.axis = .vertical
        step1Stack.spacing = 12
        step1Stack.backgroundColor = .clear
        [titleLabel, titleField,
         participantsHeaderRow, participantField,
         searchGlassWrapper, participantsContainer].forEach { step1Stack.addArrangedSubview($0) }

        // Круг кнопок шага 2
        circleShadowWrapper.backgroundColor = .clear
        circleShadowWrapper.layer.shadowColor = UIColor.black.cgColor
        circleShadowWrapper.layer.shadowOpacity = 0.25
        circleShadowWrapper.layer.shadowRadius = 14
        circleShadowWrapper.layer.shadowOffset = CGSize(width: 0, height: 10)

        circleContainer.backgroundColor = .clear
        circleContainer.clipsToBounds = true

        configureHalfButton(leftHalfButton, title: "Случайные\n40 вопросов", bg: .systemBlue)
        configureHalfButton(rightHalfButton, title: "Выбрать\nвручную", bg: .systemGreen)
        leftHalfButton.titleLabel?.numberOfLines = 2
        rightHalfButton.titleLabel?.numberOfLines = 2
        leftHalfButton.titleLabel?.textAlignment = .center
        rightHalfButton.titleLabel?.textAlignment = .center

        circleSeparator.backgroundColor = UIColor.white.withAlphaComponent(0.5)

        circleShadowWrapper.addSubview(circleContainer)
        circleContainer.addSubview(leftHalfButton)
        circleContainer.addSubview(rightHalfButton)
        circleContainer.addSubview(circleSeparator)

        circleShadowWrapper.translatesAutoresizingMaskIntoConstraints = false
        circleContainer.translatesAutoresizingMaskIntoConstraints = false
        leftHalfButton.translatesAutoresizingMaskIntoConstraints = false
        rightHalfButton.translatesAutoresizingMaskIntoConstraints = false
        circleSeparator.translatesAutoresizingMaskIntoConstraints = false

        let circleSize: CGFloat = 360
        NSLayoutConstraint.activate([
            circleContainer.widthAnchor.constraint(equalToConstant: circleSize),
            circleContainer.heightAnchor.constraint(equalTo: circleContainer.widthAnchor),

            circleContainer.leadingAnchor.constraint(equalTo: circleShadowWrapper.leadingAnchor),
            circleContainer.trailingAnchor.constraint(equalTo: circleShadowWrapper.trailingAnchor),
            circleContainer.topAnchor.constraint(equalTo: circleShadowWrapper.topAnchor),
            circleContainer.bottomAnchor.constraint(equalTo: circleShadowWrapper.bottomAnchor),

            leftHalfButton.leadingAnchor.constraint(equalTo: circleContainer.leadingAnchor),
            leftHalfButton.topAnchor.constraint(equalTo: circleContainer.topAnchor),
            leftHalfButton.bottomAnchor.constraint(equalTo: circleContainer.bottomAnchor),
            leftHalfButton.trailingAnchor.constraint(equalTo: circleContainer.centerXAnchor),

            rightHalfButton.trailingAnchor.constraint(equalTo: circleContainer.trailingAnchor),
            rightHalfButton.topAnchor.constraint(equalTo: circleContainer.topAnchor),
            rightHalfButton.bottomAnchor.constraint(equalTo: circleContainer.bottomAnchor),
            rightHalfButton.leadingAnchor.constraint(equalTo: circleContainer.centerXAnchor),

            circleSeparator.widthAnchor.constraint(equalToConstant: 1),
            circleSeparator.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            circleSeparator.topAnchor.constraint(equalTo: circleContainer.topAnchor),
            circleSeparator.bottomAnchor.constraint(equalTo: circleContainer.bottomAnchor),
        ])

        // Step 2
        step2HintLabel.text = "Выберите способ формирования теста"
        step2HintLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        step2HintLabel.textAlignment = .center

        step2Stack.axis = .vertical
        step2Stack.spacing = 16
        step2Stack.alignment = .center
        [step2HintLabel, circleShadowWrapper].forEach { step2Stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            circleShadowWrapper.widthAnchor.constraint(equalToConstant: circleSize),
            circleShadowWrapper.heightAnchor.constraint(equalToConstant: circleSize),
        ])

        // Контент
        contentStack.addArrangedSubview(headerContainer)
        contentStack.addArrangedSubview(step1Stack)
        contentStack.addArrangedSubview(step2Stack)
    }

    private func configureHalfButton(_ btn: UIButton, title: String, bg: UIColor) {
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = bg
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6)
    }

    // MARK: - Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(goBackStep), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(goNextStep), for: .touchUpInside)

        leftHalfButton.addTarget(self, action: #selector(addRandomTest), for: .touchUpInside)
        rightHalfButton.addTarget(self, action: #selector(addManualTest), for: .touchUpInside)

        titleField.textField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
        participantField.textField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        addAllStudentsButton.addTarget(self, action: #selector(addAllStudentsTapped), for: .touchUpInside)
        clearParticipantsButton.addTarget(self, action: #selector(clearParticipantsTapped), for: .touchUpInside)
    }

    @objc private func titleChanged() { updateNextButtonState() }

    @objc private func searchTextChanged() {
        applySearchFilter()
    }

    @objc private func addAllStudentsTapped() {
        guard !allStudents.isEmpty else { return }
        var didAppend = false
        for user in allStudents where participants.contains(user.id) == false {
            addedUsers.append(user)
            didAppend = true
        }
        guard didAppend else { return }
        syncParticipantsState()
    }

    @objc private func clearParticipantsTapped() {
        guard !addedUsers.isEmpty else { return }
        addedUsers.removeAll()
        participants.removeAll()
        syncParticipantsState()
    }

    private func loadAllStudents() {
        Firestore.firestore().collection("users")
            .whereField("role", isEqualTo: Role.student.rawValue)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    guard error == nil, let docs = snapshot?.documents else {
                        self.allStudents = []
                        self.searchResults = []
                        self.searchResultsTable.reloadData()
                        self.updateSearchEmptyState()
                        self.updateParticipantsActionButtons()
                        return
                    }

                    let users = docs.compactMap { self.decodeUser(from: $0) }
                    self.allStudents = self.sortedUsers(users)
                    self.applySearchFilter()
                    self.updateParticipantsActionButtons()
                }
            }
    }

    private func decodeUser(from document: QueryDocumentSnapshot) -> User? {
        let data = document.data()
        guard let json = try? JSONSerialization.data(withJSONObject: data),
              var user = try? JSONDecoder().decode(User.self, from: json) else { return nil }
        user.id = document.documentID
        return user
    }

    private func applySearchFilter() {
        let query = participantField.textField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""

        if query.isEmpty {
            searchResults = allStudents
        } else {
            searchResults = allStudents.filter { user in
                let fullName = "\(user.surname) \(user.name) \(user.lastname)".lowercased()
                let email = user.email.lowercased()
                return fullName.contains(query) || email.contains(query)
            }
        }
        searchResults = sortedUsers(searchResults)
        searchResultsTable.reloadData()
        updateSearchEmptyState()
    }

    private func sortedUsers(_ users: [User]) -> [User] {
        users.sorted { lhs, rhs in
            let lhsName = "\(lhs.surname) \(lhs.name) \(lhs.lastname)".trimmingCharacters(in: .whitespaces)
            let rhsName = "\(rhs.surname) \(rhs.name) \(rhs.lastname)".trimmingCharacters(in: .whitespaces)
            let nameOrder = lhsName.localizedCaseInsensitiveCompare(rhsName)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.email.localizedCaseInsensitiveCompare(rhs.email) == .orderedAscending
        }
    }

    private func configureSearchEmptyState() {
        emptySearchLabel.textAlignment = .center
        emptySearchLabel.numberOfLines = 0
        emptySearchLabel.font = .systemFont(ofSize: 14, weight: .medium)
        emptySearchLabel.textColor = .secondaryLabel
        searchResultsTable.backgroundView = emptySearchLabel
        updateSearchEmptyState()
    }

    private func updateSearchEmptyState() {
        let query = participantField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if allStudents.isEmpty {
            emptySearchLabel.text = "Учеников пока нет"
            emptySearchLabel.isHidden = false
            return
        }

        if searchResults.isEmpty {
            emptySearchLabel.text = query.isEmpty ? "Список пуст" : "Ничего не найдено"
            emptySearchLabel.isHidden = false
        } else {
            emptySearchLabel.isHidden = true
        }
    }

    private func updateParticipantsActionButtons() {
        let canAddAll = !allStudents.isEmpty && addedUsers.count < allStudents.count
        addAllStudentsButton.isEnabled = canAddAll
        addAllStudentsButton.alpha = canAddAll ? 1.0 : 0.55

        let canClear = !addedUsers.isEmpty
        clearParticipantsButton.isEnabled = canClear
        clearParticipantsButton.alpha = canClear ? 1.0 : 0.55
    }

    private func syncParticipantsState() {
        addedUsers = sortedUsers(addedUsers)
        participants = addedUsers.map(\.id)
        refreshParticipantsChips()
        applySearchFilter()
        updateParticipantsActionButtons()
    }

    private func addParticipant(_ user: User) {
        guard participants.contains(user.id) == false else { return }
        addedUsers.append(user)
        syncParticipantsState()
    }

    private func removeParticipant(withId userId: String) {
        guard participants.contains(userId) else { return }
        participants.removeAll { $0 == userId }
        addedUsers.removeAll { $0.id == userId }
        syncParticipantsState()
    }

    // MARK: - Participants UI
    private func refreshParticipantsChips() {
        participantsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if addedUsers.isEmpty {
            let label = UILabel()
            label.text = "Никто не добавлен"
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 15)
            participantsStack.addArrangedSubview(label)
            return
        }

        for user in addedUsers {
            let chip = makeParticipantChip(user: user)
            participantsStack.addArrangedSubview(chip)
        }
    }

    private func makeParticipantChip(user: User) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        let nameLabel = UILabel()
        nameLabel.text = "\(user.surname) \(user.name)"
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        let emailLabel = UILabel()
        emailLabel.text = user.email
        emailLabel.font = .systemFont(ofSize: 12)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeButton.tintColor = UIColor.systemRed.withAlphaComponent(0.9)
        removeButton.addAction(UIAction { [weak self] _ in
            self?.removeParticipant(withId: user.id)
        }, for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [vStack, removeButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        hStack.distribution = .equalSpacing
        hStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
        ])
        return card
    }

    // MARK: - Navigation
    @objc private func goBackStep() {
        switch currentStep {
        case .details: dismiss(animated: true)
        case .mode: currentStep = .details
        }
    }

    @objc private func goNextStep() {
        guard validateDetails() else { return }
        currentStep = .mode
    }

    private func updateNextButtonState() {
        nextButton.isEnabled = !currentTitle.isEmpty
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
    }

    private func updateStepUI(animated: Bool) {
        let apply = {
            switch self.currentStep {
            case .details:
                self.stepLabel.text = "Шаг 1 из 2"
                self.step1Stack.isHidden = false
                self.step2Stack.isHidden = true
                self.nextButton.isHidden = false
            case .mode:
                self.stepLabel.text = "Шаг 2 из 2"
                self.step1Stack.isHidden = true
                self.step2Stack.isHidden = false
                self.nextButton.isHidden = true
            }
        }
        if animated {
            UIView.transition(with: self.contentStack, duration: 0.25, options: .transitionCrossDissolve, animations: apply)
        } else { apply() }
    }

    private func validateDetails() -> Bool {
        guard !currentTitle.isEmpty else {
            showAlert(title: "Введите название", message: "Пожалуйста, укажите название теста.")
            return false
        }
        return true
    }

    // MARK: - Step 2 actions
    @objc private func addRandomTest() {
        Firestore.firestore().collection("questionBank").getDocuments { snapshot, error in
            guard error == nil, let docs = snapshot?.documents else {
                self.showAlert(title: "Ошибка", message: "Не удалось загрузить вопросы.")
                return
            }

            var allQuestions: [Questions] = []
            let group = DispatchGroup()

            for doc in docs {
                group.enter()
                Firestore.firestore()
                    .collection("questionBank")
                    .document(doc.documentID)
                    .collection("questions")
                    .getDocuments { qsnap, _ in
                        if let qdocs = qsnap?.documents {
                            let mapped = qdocs.compactMap { qdoc -> Questions? in
                                let qdata = qdoc.data()
                                return Questions(
                                    id: qdata["id"] as? String ?? "",
                                    text: qdata["text"] as? String ?? "",
                                    type: QuestionType(rawValue: qdata["type"] as? String ?? "open") ?? .open,
                                    topicId: qdata["topicId"] as? String ?? ""
                                )
                            }
                            allQuestions.append(contentsOf: mapped)
                        }
                        group.leave()
                    }
            }

            group.notify(queue: .main) {
                guard allQuestions.count >= 40 else {
                    self.showAlert(title: "Ошибка", message: "Недостаточно вопросов в базе.")
                    return
                }
                let randomQuestions = Array(allQuestions.shuffled().prefix(40))

                let vc = ManualTestViewController(testService: self.testService)
                vc.delegate = self
                vc.setPreselectedQuestions(randomQuestions)
                vc.configure(title: self.currentTitle, participants: self.participants)

                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
        }
    }

    @objc private func addManualTest() {
        guard validateDetails() else { return }
        let vc = ManualTestViewController(testService: self.testService)
        vc.delegate = self
        vc.configure(title: self.currentTitle, participants: self.participants)

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Ок", style: .default))
        present(a, animated: true)
    }
}

// MARK: - ManualTestDelegate
extension AddTestViewController: ManualTestDelegate {
    func didFinishManualSelection(title: String, dragon: DragonKind, questions: [Questions], participants: [String]) {
        testService.createTest(title: title,
                               dragon: dragon,
                               questions: questions,
                               studentIds: participants) { [weak self] result in
            switch result {
            case .success(let test):
                DispatchQueue.main.async {
                    self?.delegate?.didCreateTest(test)
                    self?.dismiss(animated: true)
                }
            case .failure(let error):
                print("Ошибка создания теста: \(error)")
            }
        }
    }
}

// MARK: - UITableView
extension AddTestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultCell.reuseId,
            for: indexPath
        ) as? SearchResultCell else {
            return UITableViewCell()
        }

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        let user = searchResults[indexPath.row]
        let isAdded = participants.contains(user.id)
        cell.configure(with: user, isAdded: isAdded) { [weak self] in
            self?.addParticipant(user)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = searchResults[indexPath.row]
        addParticipant(user)
    }
}
