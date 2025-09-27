//  AddTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

import UIKit
import FirebaseFirestore

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
        titleTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let stepLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private let titleLabel = UILabel()
    private let titleTextField = UITextField()
    private let participantsLabel = UILabel()
    private let participantTextField = UITextField()

    private let searchResultsTable = UITableView(frame: .zero, style: .plain)

    private let participantsContainer = UIView()
    private let participantsStack = UIStackView()

    private let step1Stack = UIStackView()
    private let step2Stack = UIStackView()

    private let randomButton = UIButton(type: .system)
    private let manualButton = UIButton(type: .system)
    private let step2HintLabel = UILabel()

    // MARK: - Init
    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "addtest.title".localized
        view.backgroundColor = .systemBackground

        setupUI()
        setupActions()

        searchResultsTable.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseId)
        searchResultsTable.isHidden = true
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        
        setupAutoLocalization()

        currentStep = .details
    }
    
    override func updateLocalization() {
        super.updateLocalization()
        updateLocalizedTexts()
    }
    
    private func updateLocalizedTexts() {
        title = "addtest.title".localized
        backButton.setTitle("addtest.back".localized, for: .normal)
        nextButton.setTitle("addtest.next".localized, for: .normal)
        titleLabel.text = "addtest.title_label".localized
        titleTextField.placeholder = "addtest.title_placeholder".localized
        participantsLabel.text = "addtest.participants_label".localized
        participantTextField.placeholder = "addtest.participants_placeholder".localized
        randomButton.setTitle("addtest.random_button".localized, for: .normal)
        manualButton.setTitle("addtest.manual_button".localized, for: .normal)
        step2HintLabel.text = "addtest.step2_hint".localized
        
        // Обновляем stepLabel в зависимости от текущего шага
        switch currentStep {
        case .details:
            stepLabel.text = "addtest.step1".localized
        case .mode:
            stepLabel.text = "addtest.step2".localized
        }
    }
    
    deinit {
        removeLocalizationObserver()
        updateNextButtonState()
        refreshParticipantsChips()
    }

    // MARK: - Setup UI
    private func setupUI() {
        stepLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        stepLabel.textColor = .secondaryLabel
        stepLabel.textAlignment = .center

        backButton.setTitle("addtest.back".localized, for: .normal)
        nextButton.setTitle("addtest.next".localized, for: .normal)
        nextButton.backgroundColor = .systemBlue
        nextButton.tintColor = .white
        nextButton.layer.cornerRadius = 10
        nextButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.heightAnchor.constraint(equalToConstant: 44).isActive = true

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

        titleTextField.placeholder = "addtest.title_placeholder".localized
        titleTextField.borderStyle = .roundedRect

        participantsLabel.text = "addtest.participants_label".localized
        participantsLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        participantTextField.placeholder = "addtest.participants_placeholder".localized
        participantTextField.borderStyle = .roundedRect
        participantTextField.autocapitalizationType = .none

        participantsStack.axis = .vertical
        participantsStack.spacing = 8
        participantsStack.alignment = .fill

        participantsContainer.layer.cornerRadius = 12
        participantsContainer.backgroundColor = UIColor.secondarySystemBackground
        participantsContainer.addSubview(participantsStack)
        participantsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantsStack.topAnchor.constraint(equalTo: participantsContainer.topAnchor, constant: 8),
            participantsStack.leadingAnchor.constraint(equalTo: participantsContainer.leadingAnchor, constant: 8),
            participantsStack.trailingAnchor.constraint(equalTo: participantsContainer.trailingAnchor, constant: -8),
            participantsStack.bottomAnchor.constraint(equalTo: participantsContainer.bottomAnchor, constant: -8),
        ])

        searchResultsTable.layer.cornerRadius = 8
        searchResultsTable.layer.borderColor = UIColor.separator.cgColor
        searchResultsTable.rowHeight = 50
        searchResultsTable.heightAnchor.constraint(equalToConstant: 200).isActive = true

        step1Stack.axis = .vertical
        step1Stack.spacing = 12
        [titleLabel, titleTextField,
         participantsLabel, participantTextField,
         searchResultsTable, participantsContainer].forEach { step1Stack.addArrangedSubview($0) }

        randomButton.setTitle("addtest.random_button".localized, for: .normal)
        randomButton.backgroundColor = .systemBlue
        randomButton.tintColor = .white
        randomButton.layer.cornerRadius = 12
        randomButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        manualButton.setTitle("addtest.manual_button".localized, for: .normal)
        manualButton.backgroundColor = .systemGreen
        manualButton.tintColor = .white
        manualButton.layer.cornerRadius = 12
        manualButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let buttonsStack = UIStackView(arrangedSubviews: [randomButton, manualButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 12

        step2HintLabel.text = "addtest.step2_hint".localized
        step2HintLabel.numberOfLines = 0

        step2Stack.axis = .vertical
        step2Stack.spacing = 12
        [step2HintLabel, buttonsStack].forEach { step2Stack.addArrangedSubview($0) }

        contentStack.axis = .vertical
        contentStack.spacing = 16
        [headerContainer, step1Stack, step2Stack].forEach { contentStack.addArrangedSubview($0) }

        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        backButton.addTarget(self, action: #selector(goBackStep), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(goNextStep), for: .touchUpInside)
        randomButton.addTarget(self, action: #selector(addRandomTest), for: .touchUpInside)
        manualButton.addTarget(self, action: #selector(addManualTest), for: .touchUpInside)
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)
        participantTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    }

    @objc private func titleChanged() { updateNextButtonState() }

    @objc private func searchTextChanged() {
        let query = participantTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
            label.text = "addtest.empty_list".localized
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
            showAlert(title: "Введите название", message: "Пожалуйста, укажите название теста.")
            return false
        }
        return true
    }

    // MARK: - Step 2
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
        return searchResults.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchResultCell.reuseId,
            for: indexPath
        ) as? SearchResultCell else {
            return UITableViewCell()
        }

        let user = searchResults[indexPath.row]
        cell.configure(with: user) { [weak self] in
            guard let self else { return }
            if !participants.contains(user.id) {
                participants.append(user.id)
                addedUsers.append(user)
                refreshParticipantsChips()
            }
            participantTextField.text = ""
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

// MARK: - Кастомная ячейка поиска
final class SearchResultCell: UITableViewCell {
    static let reuseId = "SearchResultCell"

    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let addButton = UIButton(type: .system)

    private var onAdd: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.font = .systemFont(ofSize: 12, weight: .light)
        emailLabel.textColor = .secondaryLabel

        let vStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        vStack.axis = .vertical
        vStack.spacing = 2

        addButton.setTitle("addtest.add_button".localized, for: .normal)
        addButton.tintColor = .systemBlue
        addButton.addAction(UIAction { [weak self] _ in self?.onAdd?() }, for: .touchUpInside)

        let hStack = UIStackView(arrangedSubviews: [vStack, addButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .equalSpacing

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: User, onAdd: @escaping () -> Void) {
        nameLabel.text = "\(user.name) \(user.surname)"
        emailLabel.text = user.email
        self.onAdd = onAdd
    }
}
