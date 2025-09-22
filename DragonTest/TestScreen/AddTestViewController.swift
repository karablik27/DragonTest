//
//  AddTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 22.09.2025.
//


import UIKit
import FirebaseFirestore


final class AddTestViewController: UIViewController {

    weak var delegate: AddTestDelegate?
    private let testService: TestServiceProtocol

    init(testService: TestServiceProtocol) {
        self.testService = testService
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private let randomButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Случайные 40 вопросов", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        b.tintColor = .white
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 12
        return b
    }()

    private let manualButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Выбрать вручную", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        b.tintColor = .white
        b.backgroundColor = .systemGreen
        b.layer.cornerRadius = 12
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        [randomButton, manualButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 60).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        }
        NSLayoutConstraint.activate([
            randomButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            manualButton.topAnchor.constraint(equalTo: randomButton.bottomAnchor, constant: 20)
        ])

        randomButton.addTarget(self, action: #selector(addRandomTest), for: .touchUpInside)
        manualButton.addTarget(self, action: #selector(addManualTest), for: .touchUpInside)
    }

    @objc private func addRandomTest() {
        let randomDragon = DragonKind.allCases.randomElement()!
        // временные заглушки-вопросы; для прод — возьми реальный рандом из questionBank
        let placeholderQuestions = (1...40).map {
            Questions(id: "q\($0)", text: "Вопрос \($0)", type: .open, topicId: "t1")
        }

        testService.createTest(title: "Рандомный тест",
                               dragon: randomDragon,
                               questions: placeholderQuestions,
                               studentIds: []) { [weak self] result in
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

    @objc private func addManualTest() {
        let vc = ManualTestViewController(testService: testService)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
}

extension AddTestViewController: ManualTestDelegate {
    func didFinishManualSelection(title: String, dragon: DragonKind, questions: [Questions]) {
        // студентский список изначально пустой
        testService.createTest(title: title,
                               dragon: dragon,
                               questions: questions,
                               studentIds: []) { [weak self] result in
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

