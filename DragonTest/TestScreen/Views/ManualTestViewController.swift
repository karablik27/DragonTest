import UIKit
import FirebaseFirestore

final class ManualTestViewController: UIViewController {

    weak var delegate: ManualTestDelegate?
    private let testService: TestServiceProtocol

    private var topics: [Topic] = []
    private var testTitle: String = ""
    private var participants: [String] = []

    private var selectedQuestions: [Questions] = [] {
        didSet { updateCounter() }
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Nav items
    private lazy var doneItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(finishSelection))
        item.isEnabled = false
        return item
    }()

    private lazy var backItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"),
                                   style: .plain,
                                   target: self,
                                   action: #selector(backTapped))
        item.accessibilityLabel = "Назад"
        return item
    }()

    // MARK: - Floating counter
    private let counterContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemRed
        v.isUserInteractionEnabled = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.25
        v.layer.shadowRadius = 9
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.layer.masksToBounds = false
        return v
    }()

    private let counterLabel: UILabel = {
        let l = UILabel()
        l.text = "0/40"
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textAlignment = .center
        l.textColor = .white
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        return l
    }()

    // MARK: - Init
    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public config
    func setPreselectedQuestions(_ questions: [Questions]) {
        var uniq: [String: Questions] = [:]
        for q in questions { uniq[q.id] = q }
        selectedQuestions = Array(uniq.values)
    }

    func configure(title: String, participants: [String]) {
        self.testTitle = title
        self.participants = participants
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Навбар
        navigationItem.leftBarButtonItem = backItem
        navigationItem.rightBarButtonItem = doneItem

        // Плавающий счётчик
        setupFloatingCounter()

        updateCounter()
        loadTopicsAndQuestions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Свайп-назад остаётся активным при кастомной кнопке back
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // Скругление под фактическую высоту (капсула)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        counterContainer.layer.cornerRadius = counterContainer.bounds.height / 2
    }

    private func setupFloatingCounter() {
        let padX: CGFloat = 14
        let padY: CGFloat = 8

        counterContainer.addSubview(counterLabel)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            counterLabel.leadingAnchor.constraint(equalTo: counterContainer.leadingAnchor, constant: padX),
            counterLabel.trailingAnchor.constraint(equalTo: counterContainer.trailingAnchor, constant: -padX),
            counterLabel.topAnchor.constraint(equalTo: counterContainer.topAnchor, constant: padY),
            counterLabel.bottomAnchor.constraint(equalTo: counterContainer.bottomAnchor, constant: -padY)
        ])

        view.addSubview(counterContainer)
        counterContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            counterContainer.heightAnchor.constraint(equalToConstant: 70),
            counterContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            counterContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func updateCounter() {
        let count = selectedQuestions.count
        counterLabel.text = "\(count)/40"
        doneItem.isEnabled = (count == 40)
    }

    // MARK: - Actions
    @objc private func backTapped() {
        if let nav = navigationController {
            if nav.viewControllers.first === self {
                dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func finishSelection() {
        guard selectedQuestions.count == 40 else {
            showAlert(title: "Ошибка", message: "Нужно выбрать ровно 40 вопросов!")
            return
        }
        let dragon = DragonKind.allCases.randomElement()!
        delegate?.didFinishManualSelection(
            title: testTitle,
            dragon: dragon,
            questions: selectedQuestions,
            participants: participants
        )
        dismiss(animated: true)
    }

    // MARK: - Firestore
    private func loadTopicsAndQuestions() {
        Firestore.firestore().collection("questionBank").getDocuments { [weak self] snapshot, _ in
            guard let self = self, let docs = snapshot?.documents else { return }
            self.topics = docs.compactMap { doc in
                let data = doc.data()
                return Topic(
                    id: doc.documentID,
                    title: data["title"] as? String ?? "Без названия",
                    questions: []
                )
            }

            let group = DispatchGroup()
            for i in 0..<self.topics.count {
                let topicId = self.topics[i].id
                group.enter()
                Firestore.firestore()
                    .collection("questionBank")
                    .document(topicId)
                    .collection("questions")
                    .getDocuments { [weak self] qsnap, _ in
                        guard let self = self else { group.leave(); return }
                        self.topics[i].questions = qsnap?.documents.compactMap { qdoc in
                            let qdata = qdoc.data()
                            return Questions(
                                id: (qdata["id"] as? String).flatMap { !$0.isEmpty ? $0 : nil } ?? qdoc.documentID,
                                text: qdata["text"] as? String ?? "",
                                type: QuestionType(rawValue: qdata["type"] as? String ?? "open") ?? .open,
                                topicId: qdata["topicId"] as? String ?? topicId
                            )
                        }
                        group.leave()
                    }
            }
            group.notify(queue: .main) {
                self.tableView.reloadData()
                self.preselectRowsIfNeeded()
            }
        }
    }

    private func preselectRowsIfNeeded() {
        guard !selectedQuestions.isEmpty else { return }
        let selectedIds = Set(selectedQuestions.map { $0.id })
        for (sectionIndex, topic) in topics.enumerated() {
            guard let questions = topic.questions else { continue }
            for (rowIndex, q) in questions.enumerated() {
                if selectedIds.contains(q.id) {
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        updateCounter()
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table delegates
extension ManualTestViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { topics.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        topics[section].questions?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        topics[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let q = topics[indexPath.section].questions?[indexPath.row] {
            cell.textLabel?.text = q.text
        } else {
            cell.textLabel?.text = "—"
        }
        return cell
    }

    // Запрет выбора > 40
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectedQuestions.count >= 40 {
            showAlert(title: "Лимит", message: "Вы уже выбрали 40 вопросов. Снимите выбор, чтобы выбрать другой.")
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let q = topics[indexPath.section].questions?[indexPath.row] else { return }
        if selectedQuestions.contains(where: { $0.id == q.id }) { return }
        if selectedQuestions.count < 40 {
            selectedQuestions.append(q)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            showAlert(title: "Лимит", message: "Нельзя выбрать больше 40 вопросов.")
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let q = topics[indexPath.section].questions?[indexPath.row] {
            selectedQuestions.removeAll { $0.id == q.id }
        }
    }
}
