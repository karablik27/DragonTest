//
//  TeacherReviewViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 23.09.2025.
//

import UIKit
import FirebaseFirestore

// MARK: - VC
final class TeacherReviewViewController: UIViewController, TeacherReviewViewProtocol {
    private enum RowFilter: Int {
        case all = 0
        case pending = 1
        case reviewed = 2
        case noAnswers = 3
    }

    // DI
    private let test: Test
    private var presenter: TeacherReviewPresenterProtocol!
    private let colors: [CGColor]

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerCard = ResultGlassCard()
    private let testTitlePill = PillLabel(text: "", style: .white)
    private let headerTitleLabel = UILabel()
    private let countLabel = UILabel()
    private let searchFieldGlass = FieldGlass(radius: 14)
    private let searchField = UITextField()
    private let filterControl = UISegmentedControl(items: ["Все", "На проверке", "Проверено", "Без ответа"])
    private let emptyStateLabel = UILabel()

    // data
    private var allRows: [StudentRowModel] = []
    private var rows: [StudentRowModel] = []
    private let photoCache = NSCache<NSString, UIImage>()
    private var photoTasks: [String: Task<UIImage?, Never>] = [:]
    private var currentFilter: RowFilter = .all

    // внешний колбэк
    var onClose: (() -> Void)?

    private lazy var avatarPlaceholder: UIImage? = {
        UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate)
    }()

    // MARK: Init
    init(test: Test, colors: [CGColor]) {
        self.test = test
        self.colors = colors
        super.init(nibName: nil, bundle: nil)
        self.presenter = TeacherReviewPresenter(view: self, test: test)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupNavigation()
        setupTable()
        configureHeaderControls()
        testTitlePill.setText(test.title)
        tableView.tableHeaderView = makeHeaderView()

        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        relayoutHeader()
    }

    // MARK: BG = как у экрана результатов
    private func setupBackground() {
        view.backgroundColor = .clear
        GradientBackground.attach(to: view, colors: colors)
    }

    // MARK: Navigation
    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.up"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationController?.navigationBar.tintColor = .label
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil
        title = nil
    }

    @objc private func closeTapped() { onClose?() }

    // MARK: Table
    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
        tableView.sectionHeaderTopPadding = 0
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 108

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(TeacherStudentCell.self, forCellReuseIdentifier: "TeacherStudentCell")

        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        emptyStateLabel.text = "Загрузка учеников..."
        tableView.backgroundView = emptyStateLabel

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureHeaderControls() {
        headerTitleLabel.text = "Выберите ученика"
        headerTitleLabel.textAlignment = .center
        headerTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        headerTitleLabel.textColor = .white.withAlphaComponent(0.95)

        countLabel.textAlignment = .center
        countLabel.font = .systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        countLabel.text = "Показано 0 из 0"

        searchField.attributedPlaceholder = NSAttributedString(
            string: "Поиск по фамилии, имени или email",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.56)]
        )
        searchField.textColor = .white
        searchField.tintColor = .white
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .done
        searchField.autocorrectionType = .no
        searchField.autocapitalizationType = .none
        searchField.spellCheckingType = .no
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.delegate = self

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = UIColor.white.withAlphaComponent(0.7)
        searchIcon.contentMode = .scaleAspectFit
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true

        let searchStack = UIStackView(arrangedSubviews: [searchIcon, searchField])
        searchStack.axis = .horizontal
        searchStack.alignment = .center
        searchStack.spacing = 8
        searchStack.translatesAutoresizingMaskIntoConstraints = false
        searchFieldGlass.addSubview(searchStack)
        NSLayoutConstraint.activate([
            searchStack.topAnchor.constraint(equalTo: searchFieldGlass.topAnchor, constant: 9),
            searchStack.leadingAnchor.constraint(equalTo: searchFieldGlass.leadingAnchor, constant: 12),
            searchStack.trailingAnchor.constraint(equalTo: searchFieldGlass.trailingAnchor, constant: -12),
            searchStack.bottomAnchor.constraint(equalTo: searchFieldGlass.bottomAnchor, constant: -9),
            searchFieldGlass.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        filterControl.selectedSegmentIndex = 0
        filterControl.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        filterControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.30)
        filterControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white.withAlphaComponent(0.78),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ], for: .normal)
        filterControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .bold)
        ], for: .selected)
        filterControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }

    private func makeHeaderView() -> UIView {
        if headerCard.subviews.isEmpty {
            let v = UIStackView(arrangedSubviews: [headerTitleLabel, testTitlePill, countLabel, searchFieldGlass, filterControl])
            v.axis = .vertical
            v.spacing = 10

            headerCard.translatesAutoresizingMaskIntoConstraints = false
            headerCard.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                v.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 14),
                v.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
                v.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16),
                v.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -14)
            ])
        }

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(headerCard)
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            headerCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            headerCard.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        container.layoutIfNeeded()
        let width = effectiveTableWidth()
        let size = container.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: CGSize(width: width, height: size.height))
        return container
    }

    private func effectiveTableWidth() -> CGFloat {
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        return width > 0 ? width : UIScreen.main.bounds.width
    }

    private func relayoutHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let width = effectiveTableWidth()
        let target = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if abs(header.frame.width - width) > 0.5 || abs(header.frame.height - target.height) > 0.5 {
            header.frame.size.width = width
            header.frame.size.height = target.height
            tableView.tableHeaderView = header
        }
    }

    // MARK: TeacherReviewViewProtocol
    func showStudents(_ rows: [StudentRowModel]) {
        allRows = sortRows(rows)
        applyFiltersAndReload()
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: Фото из Firestore (profilePhoto/{userId}.photoBase64)
    private func loadPhoto(userId: String, into imageView: UIImageView) {
        imageView.accessibilityIdentifier = userId
        imageView.image = avatarPlaceholder
        imageView.tintColor = .white.withAlphaComponent(0.6)

        if let img = photoCache.object(forKey: userId as NSString) {
            imageView.image = img
            return
        }

        let createdTask: Bool
        let task: Task<UIImage?, Never>
        if let inFlight = photoTasks[userId] {
            task = inFlight
            createdTask = false
        } else {
            let newTask = Task<UIImage?, Never> {
                do {
                    let doc = try await Firestore.firestore()
                        .collection("profilePhoto")
                        .document(userId)
                        .getDocument()
                    if let base64 = doc.data()?["photoBase64"] as? String,
                       let data = Data(base64Encoded: base64),
                       let image = UIImage(data: data) {
                        return image
                    }
                } catch {}
                return nil
            }
            photoTasks[userId] = newTask
            task = newTask
            createdTask = true
        }

        Task { [weak self, weak imageView] in
            let image = await task.value
            if let image {
                self?.photoCache.setObject(image, forKey: userId as NSString)
            }
            await MainActor.run {
                guard let imageView, imageView.accessibilityIdentifier == userId else { return }
                if let image { imageView.image = image }
            }
            if createdTask {
                self?.photoTasks[userId] = nil
            }
        }
    }

    private func sortRows(_ rows: [StudentRowModel]) -> [StudentRowModel] {
        rows.sorted { lhs, rhs in
            let lhsStatus = status(for: lhs.attempt)
            let rhsStatus = status(for: rhs.attempt)
            let lhsPriority = priority(for: lhsStatus)
            let rhsPriority = priority(for: rhsStatus)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }

            let lhsName = "\(lhs.user.surname) \(lhs.user.name) \(lhs.user.lastname)".trimmingCharacters(in: .whitespaces)
            let rhsName = "\(rhs.user.surname) \(rhs.user.name) \(rhs.user.lastname)".trimmingCharacters(in: .whitespaces)
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    private func priority(for status: TeacherStudentCell.Status) -> Int {
        switch status {
        case .llmPending: return 0
        case .llmDoneWaitTeacher: return 1
        case .teacherDone: return 2
        case .notPassed: return 3
        }
    }

    @objc private func searchChanged() {
        applyFiltersAndReload()
    }

    @objc private func filterChanged() {
        currentFilter = RowFilter(rawValue: filterControl.selectedSegmentIndex) ?? .all
        applyFiltersAndReload()
    }

    private func applyFiltersAndReload() {
        let query = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        rows = allRows.filter { row in
            let status = status(for: row.attempt)
            guard matchesFilter(status: status) else { return false }
            guard !query.isEmpty else { return true }

            let fullName = "\(row.user.surname) \(row.user.name) \(row.user.lastname)".lowercased()
            let email = row.user.email.lowercased()
            return fullName.contains(query) || email.contains(query)
        }

        countLabel.text = "Показано \(rows.count) из \(allRows.count)"
        tableView.reloadData()
        updateEmptyState(query: query)
        relayoutHeader()
    }

    private func matchesFilter(status: TeacherStudentCell.Status) -> Bool {
        switch currentFilter {
        case .all:
            return true
        case .pending:
            return status == .llmPending || status == .llmDoneWaitTeacher
        case .reviewed:
            return status == .teacherDone
        case .noAnswers:
            return status == .notPassed
        }
    }

    private func updateEmptyState(query: String) {
        let text: String
        if allRows.isEmpty {
            text = "В этом тесте пока нет учеников"
        } else if query.isEmpty, currentFilter == .all {
            text = "Список пуст"
        } else {
            text = "По выбранному фильтру ничего не найдено"
        }
        emptyStateLabel.text = text
        emptyStateLabel.isHidden = !rows.isEmpty
    }
}

// MARK: - TableView
extension TeacherReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeacherStudentCell", for: indexPath) as! TeacherStudentCell
        let canOpen = row.attempt != nil
        cell.configure(
            name: "\(row.user.surname) \(row.user.name)",
            subtitle: row.user.email,
            status: status(for: row.attempt),
            canOpen: canOpen
        )
        loadPhoto(userId: row.user.id, into: cell.avatarView)
        return cell
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        rows[indexPath.row].attempt != nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rows[indexPath.row]
        guard let attempt = row.attempt else { return }

        let vc = TeacherReviewDetailViewController(
            attempt: attempt,
            questions: test.questions,
            answerService: DependencyInjection.shared.answerService,
            colors: self.colors,
            testTitle: self.test.title
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    private func status(for attempt: StudentAttempt?) -> TeacherStudentCell.Status {
        guard let attempt else { return .notPassed }
        if attempt.result?.teacherReviewedAt != nil { return .teacherDone }
        if attempt.result?.llmReviewedAt != nil || attempt.resultId != nil { return .llmDoneWaitTeacher }
        return .llmPending
    }
}

extension TeacherReviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
