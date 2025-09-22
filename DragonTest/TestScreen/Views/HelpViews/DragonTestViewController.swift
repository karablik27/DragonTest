//
//  DragonTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//


import UIKit

final class DragonTestViewController: UIViewController {
    private var test: DragonTest
    private var currentIndex = 0
    private var correctAnswers = 0
    
    private let colors: [CGColor]
    private let questionLabel = UILabel()
    private var answerButtons: [UIButton] = []
    
    private let onFinish: (Int) -> Void
    
    init(test: DragonTest, colors: [CGColor], onFinish: @escaping (Int) -> Void) {
        self.test = test
        self.colors = colors
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupUI()
        showQuestion()
    }
    
    private func setupBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = colors
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first { $0 is CAGradientLayer }?.frame = view.bounds
    }
    
    private func setupUI() {
        questionLabel.font = .systemFont(ofSize: 22, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        
        view.addSubview(questionLabel)
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        var last: UIView = questionLabel
        for i in 0..<3 {
            let b = UIButton(type: .system)
            b.tag = i
            b.setTitleColor(.white, for: .normal)
            b.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            b.layer.cornerRadius = 8
            b.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            b.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            
            view.addSubview(b)
            b.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                b.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 20),
                b.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                b.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                b.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            last = b
            answerButtons.append(b)
        }
    }
    
    private func showQuestion() {
        guard currentIndex < test.questions.count else {
            finishTest()
            return
        }
        let q = test.questions[currentIndex]
        questionLabel.text = q.text
        for (i, b) in answerButtons.enumerated() {
            b.setTitle(q.answers[i], for: .normal)
        }
    }
    
    @objc private func answerTapped(_ sender: UIButton) {
        let q = test.questions[currentIndex]
        if sender.tag == q.correctIndex {
            correctAnswers += 1
        }
        currentIndex += 1
        showQuestion()
    }
    
    private func finishTest() {
        let percent = Int((Double(correctAnswers) / Double(test.questions.count)) * 100)
        let message = percent == 100 ? "Ты поймал дракона 🎉" : "Результат: \(percent)%"

        let alert = UIAlertController(title: "Тест завершён", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { _ in
            self.onFinish(self.test.completed)
        }))
        present(alert, animated: true)
    }
}
