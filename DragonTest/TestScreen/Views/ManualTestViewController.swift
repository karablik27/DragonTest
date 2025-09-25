//  ManualTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//

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

    private lazy var counterItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "0/40", style: .plain, target: nil, action: nil)
        item.isEnabled = false
        return item
    }()

    private lazy var doneItem: UIBarButtonItem = {
        UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(finishSelection))
    }()

    // MARK: - Init
    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Config
    func setPreselectedQuestions(_ questions: [Questions]) {
        selectedQuestions = questions
    }

    func configure(title: String, participants: [String]) {
        self.testTitle = title
        self.participants = participants
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Выбор вопросов"
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

        navigationItem.rightBarButtonItems = [counterItem, doneItem]
        updateCounter()

        loadTopicsAndQuestions()
    }

    private func updateCounter() {
        counterItem.title = "\(selectedQuestions.count)/40"
    }

    // MARK: - Firestore
    private func loadTopicsAndQuestions() {
        Firestore.firestore().collection("questionBank").getDocuments { snapshot, _ in
            guard let docs = snapshot?.documents else { return }
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
                    .getDocuments { qsnap, _ in
                        self.topics[i].questions = qsnap?.documents.compactMap { qdoc in
                            let qdata = qdoc.data()
                            return Questions(
                                id: qdata["id"] as? String ?? "",
                                text: qdata["text"] as? String ?? "",
                                type: QuestionType(rawValue: qdata["type"] as? String ?? "open") ?? .open,
                                topicId: qdata["topicId"] as? String ?? ""
                            )
                        }
                        group.leave()
                    }
            }
            group.notify(queue: .main) {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Finish
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
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let q = topics[indexPath.section].questions?[indexPath.row] {
            selectedQuestions.append(q)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let q = topics[indexPath.section].questions?[indexPath.row] {
            selectedQuestions.removeAll { $0.id == q.id }
        }
    }
}
