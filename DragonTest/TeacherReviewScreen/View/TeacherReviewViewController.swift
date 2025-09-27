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

    // DI
    private let test: Test
    private var presenter: TeacherReviewPresenterProtocol!
    private let colors: [CGColor]

    // UI
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerCard = ResultGlassCard()
    private let testTitlePill = PillLabel(text: "", style: .white)

    // data
    private var rows: [StudentRowModel] = []
    private let photoCache = NSCache<NSString, UIImage>()

    // внешний колбэк
    var onClose: (() -> Void)?

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
        testTitlePill.setText(test.title)
        tableView.tableHeaderView = makeHeaderView()

        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let size = header.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != size.height {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(TeacherStudentCell.self, forCellReuseIdentifier: "TeacherStudentCell")

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeHeaderView() -> UIView {
        let title = UILabel()
        title.text = "Ученики"
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.textColor = .white.withAlphaComponent(0.95)

        let v = UIStackView(arrangedSubviews: [title, testTitlePill])
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

        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(headerCard)
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            headerCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            headerCard.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])

        container.layoutIfNeeded()
        let size = container.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        container.frame = CGRect(origin: .zero, size: size)
        return container
    }

    // MARK: TeacherReviewViewProtocol
    func showStudents(_ rows: [StudentRowModel]) {
        self.rows = rows
        tableView.reloadData()
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: Фото из Firestore (profilePhoto/{userId}.photoBase64)
    private func loadPhoto(userId: String, into imageView: UIImageView) {
        if let img = photoCache.object(forKey: userId as NSString) {
            imageView.image = img; return
        }
        Task {
            do {
                let doc = try await Firestore.firestore()
                    .collection("profilePhoto").document(userId).getDocument()
                if let base64 = doc.data()?["photoBase64"] as? String,
                   let data = Data(base64Encoded: base64),
                   let image = UIImage(data: data) {
                    photoCache.setObject(image, forKey: userId as NSString)
                    await MainActor.run { imageView.image = image }
                }
            } catch {}
        }
    }
}

// MARK: - TableView
extension TeacherReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeacherStudentCell", for: indexPath) as! TeacherStudentCell
        cell.configure(name: "\(row.user.surname) \(row.user.name)", status: status(for: row.attempt))
        loadPhoto(userId: row.user.id, into: cell.avatarView)
        return cell
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

