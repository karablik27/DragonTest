//  TeacherReviewViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
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
    private let tableView = UITableView(frame: .zero, style: .plain) // полноширинные карточки
    private let headerCard = ResultGlassCard()
    private let testTitlePill = PillLabel(text: "", style: .white)

    // data
    private var rows: [StudentRowModel] = []
    private let photoCache = NSCache<NSString, UIImage>()

    // внешний колбэк (закрыть экран)
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

        // шапка
        testTitlePill.setText(test.title)
        tableView.tableHeaderView = makeHeaderView()

        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // подгоняем высоту header под ширину экрана
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
        // стрелка вверх, чёрная
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.up"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationController?.navigationBar.tintColor = .label
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = nil // заголовок в шапке-плашке
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
            container.widthAnchor.constraint(equalToConstant: view.bounds.width) // важно для автоподбора высоты
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
            } catch {
                // игнорим; остаётся плейсхолдер
            }
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
        if attempt.reviewed { return .teacherDone }
        if attempt.resultId != nil { return .llmDoneWaitTeacher }
        return .llmPending
    }
}

// MARK: - Cell
final class TeacherStudentCell: UITableViewCell {
    enum Status { case teacherDone, llmDoneWaitTeacher, llmPending, notPassed }

    let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let statusGlass = FieldGlass(radius: 10)
    private let statusLabel = InsetLabel()
    private let card = ResultGlassCard(radius: 22)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Avatar
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.image = UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate)
        avatarView.tintColor = .white.withAlphaComponent(0.6)
        avatarView.layer.cornerRadius = 28
        avatarView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        avatarView.layer.borderWidth = 1.0 / UIScreen.main.scale
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 56),
            avatarView.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Name
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 1

        // Status (стеклянная плашка)
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.contentInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        statusLabel.numberOfLines = 1

        statusGlass.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusGlass.topAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: statusGlass.leadingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: statusGlass.trailingAnchor, constant: -4),
            statusLabel.bottomAnchor.constraint(equalTo: statusGlass.bottomAnchor, constant: -2),
            statusGlass.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        let textStack = UIStackView(arrangedSubviews: [nameLabel, statusGlass])
        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.alignment = .fill

        let h = UIStackView(arrangedSubviews: [avatarView, textStack])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12

        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            h.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            h.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            h.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            h.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, status: Status) {
        nameLabel.text = name
        switch status {
        case .teacherDone:
            statusLabel.text = "✅ Проверено учителем"
            statusGlass.backgroundColor = ResultStyle.okAccent.withAlphaComponent(0.28)
        case .llmDoneWaitTeacher:
            statusLabel.text = "🤖 Проверено ИИ, ждёт учителя"
            statusGlass.backgroundColor = ResultStyle.aiAccent.withAlphaComponent(0.28)
        case .llmPending:
            statusLabel.text = "⏳ На проверке (ИИ)"
            statusGlass.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        case .notPassed:
            statusLabel.text = "❌ Не прошёл"
            statusGlass.backgroundColor = UIColor.red.withAlphaComponent(0.30)
        }
    }
}
