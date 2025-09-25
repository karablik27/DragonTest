//
//  TeacherReviewViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 23.09.2025.
//

import UIKit

final class TeacherReviewViewController: UIViewController, TeacherReviewViewProtocol {
    
    private let test: Test
    private var presenter: TeacherReviewPresenterProtocol!
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var rows: [StudentRowModel] = []
    
    init(test: Test) {
        self.test = test
        super.init(nibName: nil, bundle: nil)
        self.presenter = TeacherReviewPresenter(view: self, test: test)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ученики: \(test.title)"
        view.backgroundColor = .systemBackground
        setupTable()
        presenter.viewDidLoad()
    }
    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - TeacherReviewViewProtocol
    func showStudents(_ rows: [StudentRowModel]) {
        self.rows = rows
        tableView.reloadData()
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension TeacherReviewViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let user = row.user
        let attempt = row.attempt
        
        cell.textLabel?.text = "\(user.surname) \(user.name) – " +
        (attempt == nil ? "❌ Не прошёл" :
         attempt?.reviewed == true ? "✅ Проверен" : "⏳ На проверке")
        
        cell.accessoryType = attempt == nil ? .none : .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let attempt = row.attempt else { return }
        
        let vc = TeacherReviewDetailViewController(
            attempt: attempt,
            questions: test.questions,
            answerService: DependencyInjection.shared.answerService
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
