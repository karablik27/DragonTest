//  AddTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import UIKit
import FirebaseFirestore

// MARK: - Стеклянная карточка (прозрачная, без белой заливки)
final class GlassView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let borderLayer = CAShapeLayer()
    private let corner: CGFloat

    init(radius: CGFloat = 20) {
        self.corner = radius
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Едва заметная «ледяная» обводка
        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: corner)
        borderLayer.path = path.cgPath
        borderLayer.frame = bounds
    }
}

// MARK: - Стеклянное текстовое поле (без белого фона)
final class GlassTextField: UIView {
    let textField = UITextField()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let borderLayer = CAShapeLayer()
    private let corner: CGFloat = 12

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    init(placeholder: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = corner
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // поле
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.placeholder = placeholder
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        addSubview(textField)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.35).cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1.0 / UIScreen.main.scale
        layer.addSublayer(borderLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: corner).cgPath
        borderLayer.frame = bounds
    }
}

// MARK: - Основной контроллер
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
    private let titleField = GlassTextField(placeholder: "addtest.title_placeholder".localized)
    private let participantsLabel = UILabel()
    private let participantField = GlassTextField(placeholder: "addtest.participants_placeholder".localized)

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
    private let leftHalfButton = UIButton(type: .system)   // Случайные
    private let rightHalfButton = UIButton(type: .system)  // Вручную
    private let circleSeparator = UIView()
    private let step2HintLabel = UILabel()

    // MARK: - Localization References
    private weak var backButtonRef: UIButton?
    private weak var nextButtonRef: UIButton?
    private weak var stepLabelRef: UILabel?
    private weak var titleLabelRef: UILabel?
    private weak var participantsLabelRef: UILabel?
    private weak var leftHalfButtonRef: UIButton?
    private weak var rightHalfButtonRef: UIButton?
    private weak var step2HintLabelRef: UILabel?

    // MARK: - Init
    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen // чтобы просвечивал фон за контроллером
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Полностью прозрачный фон экрана
        view.backgroundColor = .clear
        view.isOpaque = false

        setupUI()
        setupActions()

        searchResultsTable.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseId)
        searchResultsTable.isHidden = true
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        setupAutoLocalization()

        currentStep = .details
        updateNextButtonState()
        refreshParticipantsChips()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        circleContainer.layer.cornerRadius = circleContainer.bounds.width / 2
        if #available(iOS 13.0, *) { circleContainer.layer.cornerCurve = .continuous }
    }
    
    // MARK: - Localization
    override func updateLocalization() {
        super.updateLocalization()
        
        backButtonRef?.setTitle("addtest.back".localized, for: .normal)
        nextButtonRef?.setTitle("addtest.next".localized, for: .normal)
        titleLabelRef?.text = "addtest.title_label".localized
        participantsLabelRef?.text = "addtest.participants_label".localized
        step2HintLabelRef?.text = "addtest.step2_hint".localized
        
        // Update placeholders
        titleField.textField.placeholder = "addtest.title_placeholder".localized
        participantField.textField.placeholder = "addtest.participants_placeholder".localized
        
        // Update buttons
        leftHalfButtonRef?.setTitle("addtest.random_button".localized, for: .normal)
        rightHalfButtonRef?.setTitle("addtest.manual_button".localized, for: .normal)
        
        // Update step labels
        switch currentStep {
        case .details:
            stepLabelRef?.text = "addtest.step1".localized
        case .mode:
            stepLabelRef?.text = "addtest.step2".localized
        }
    }

    // MARK: - Setup UI
    private func setupUI() {
        // Scroll & Stack
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
        self.stepLabelRef = stepLabel

        backButton.setTitle("addtest.back".localized, for: .normal)
        nextButton.setTitle("addtest.next".localized, for: .normal)
        self.backButtonRef = backButton
        self.nextButtonRef = nextButton
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
        titleLabel.text = "addtest.title_label".localized
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        self.titleLabelRef = titleLabel

        participantsLabel.text = "addtest.participants_label".localized
        participantsLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        self.participantsLabelRef = participantsLabel

        // Таблица поиска — полностью прозрачная
        searchResultsTable.layer.cornerRadius = 12
        searchResultsTable.clipsToBounds = true
        searchResultsTable.backgroundColor = .clear
        searchResultsTable.isOpaque = false
        searchResultsTable.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        searchResultsTable.tableHeaderView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))
        searchResultsTable.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))

        searchGlassWrapper.addSubview(searchResultsTable)
        searchGlassWrapper.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTable.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchResultsTable.topAnchor.constraint(equalTo: searchGlassWrapper.topAnchor),
            searchResultsTable.leadingAnchor.constraint(equalTo: searchGlassWrapper.leadingAnchor),
            searchResultsTable.trailingAnchor.constraint(equalTo: searchGlassWrapper.trailingAnchor),
            searchResultsTable.bottomAnchor.constraint(equalTo: searchGlassWrapper.bottomAnchor),
            searchGlassWrapper.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Контейнер выбранных участников
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
         participantsLabel, participantField,
         searchGlassWrapper, participantsContainer].forEach { step1Stack.addArrangedSubview($0) }

        // Круг кнопок шага 2
        circleShadowWrapper.backgroundColor = .clear
        circleShadowWrapper.layer.shadowColor = UIColor.black.cgColor
        circleShadowWrapper.layer.shadowOpacity = 0.25
        circleShadowWrapper.layer.shadowRadius = 14
        circleShadowWrapper.layer.shadowOffset = CGSize(width: 0, height: 10)

        circleContainer.backgroundColor = .clear
        circleContainer.clipsToBounds = true

        configureHalfButton(leftHalfButton, title: "addtest.random_button".localized, bg: .systemBlue)
        configureHalfButton(rightHalfButton, title: "addtest.manual_button".localized, bg: .systemGreen)
        self.leftHalfButtonRef = leftHalfButton
        self.rightHalfButtonRef = rightHalfButton
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
        step2HintLabel.text = "addtest.step2_hint".localized
        step2HintLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        step2HintLabel.textAlignment = .center
        self.step2HintLabelRef = step2HintLabel

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
    }

    @objc private func titleChanged() { updateNextButtonState() }

    @objc private func searchTextChanged() {
        let query = participantField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.count < 2 {
            searchResults = []
            searchResultsTable.isHidden = true
            searchResultsTable.reloadData()
            return
        }
        searchStudents(query: query) { [weak self] users in
            DispatchQueue.main.async {
                self?.searchResults = users
                self?.searchResultsTable.isHidden = users.isEmpty
                self?.searchResultsTable.reloadData()
            }
        }
    }

    private func searchStudents(query: String, completion: @escaping ([User]) -> Void) {
        Firestore.firestore().collection("users")
            .whereField("role", isEqualTo: Role.student.rawValue)
            .getDocuments { snapshot, error in
                guard error == nil, let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                let all = docs.compactMap { doc -> User? in
                    let data = doc.data()
                    guard let json = try? JSONSerialization.data(withJSONObject: data),
                          var user = try? JSONDecoder().decode(User.self, from: json) else { return nil }
                    user.id = doc.documentID
                    return user
                }
                let filtered = all.filter { u in
                    let fullName = "\(u.name.lowercased()) \(u.surname.lowercased())"
                    let email = u.email.lowercased()
                    let q = query.lowercased()
                    return fullName.contains(q) || email.contains(q)
                }
                completion(filtered)
            }
    }

    // MARK: - Participants UI
    private func refreshParticipantsChips() {
        participantsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if addedUsers.isEmpty {
            let label = UILabel()
            label.text = "Список пуст"
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 15)
            participantsStack.addArrangedSubview(label)
        } else {
            for (index, user) in addedUsers.enumerated() {
                let chip = makeParticipantChip(user: user, index: index)
                participantsStack.addArrangedSubview(chip)
            }
        }
    }

    private func makeParticipantChip(user: User, index: Int) -> UIView {
        let nameLabel = UILabel()
        nameLabel.text = "\(user.name) \(user.surname)"
        nameLabel.font = .systemFont(ofSize: 14)

        let emailLabel = UILabel()
        emailLabel.text = user.email
        emailLabel.font = .systemFont(ofSize: 12)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        let removeButton = UIButton(type: .system)
        removeButton.setTitle("✕", for: .normal)
        removeButton.tintColor = .systemRed
        removeButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            guard index < self.participants.count, index < self.addedUsers.count else { return }
            self.participants.remove(at: index)
            self.addedUsers.remove(at: index)
            self.refreshParticipantsChips()
        }, for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [vStack, removeButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 8
        hStack.distribution = .equalSpacing
        return hStack
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
                self.stepLabel.text = "addtest.step1".localized
                self.step1Stack.isHidden = false
                self.step2Stack.isHidden = true
                self.nextButton.isHidden = false
            case .mode:
                self.stepLabel.text = "addtest.step2".localized
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
            showAlert(title: "alert.error".localized, message: "addtest.empty_title_error".localized)
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
        a.addAction(UIAlertAction(title: "alert.ok".localized, style: .default))
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

        // никакой белой подложки
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none

        let user = searchResults[indexPath.row]
        cell.configure(with: user) { [weak self] in
            guard let self else { return }
            if !participants.contains(user.id) {
                participants.append(user.id)
                addedUsers.append(user)
                refreshParticipantsChips()
            }
            participantField.textField.text = ""
            searchResults = []
            searchResultsTable.reloadData()
            searchResultsTable.isHidden = true
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

