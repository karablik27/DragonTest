//
//  DragonTestViewController.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//

import UIKit

// MARK: - Custom UITextField (запрещаем вставку/выделение + добавляем Done)
final class NoPasteTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) ||
            action == #selector(select(_:)) ||
            action == #selector(selectAll(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    func addDoneButtonOnKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.setItems([flexSpace, doneButton], animated: false)

        self.inputAccessoryView = toolbar
    }

    @objc private func doneButtonTapped() {
        self.resignFirstResponder()
    }
}

final class DragonTestViewController: UIViewController {

    // MARK: - Data
    private var test: Test
    private var currentIndex = 0
    private var attempt: StudentAttempt

    // MARK: - Timer
    private var timer: Timer?
    private var timeRemaining: TimeInterval = 3600 // 1 час
    private let timerLabel = UILabel()

    // MARK: - UI (secure root)
    private let colors: [CGColor]
    private let questionLabel = UILabel()
    private var answerButtons: [UIButton] = []
    private let textField = NoPasteTextField()
    private let nextButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Продолжить", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        b.layer.cornerRadius = 10
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.isHidden = true
        return b
    }()

    private let questionNumbersCollection: UICollectionView
    private let onFinish: (Int) -> Void

    // MARK: - Init
    init(test: Test, colors: [CGColor], onFinish: @escaping (Int) -> Void) {
        self.test = test
        self.colors = colors
        self.onFinish = onFinish

        let studentId = DependencyInjection.shared.currentUser.userId ?? "unknown"
        self.attempt = StudentAttempt(
            id: UUID().uuidString,
            testId: test.id,
            studentId: studentId,
            answers: [],
            submittedAt: Date(),
            reviewed: false,
            result: nil
        )

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 36, height: 36)
        self.questionNumbersCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.questionNumbersCollection.showsHorizontalScrollIndicator = false

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Secure root view (как в твоём рабочем примере)
    override func loadView() {
        let secureTextField = UITextField()
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false

        if let secureView = secureTextField.layer.sublayers?.first?.delegate as? UIView {
            secureView.backgroundColor = .black
            self.view = secureView
        } else {
            self.view = UIView()
            self.view.backgroundColor = .black
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupCollection()
        setupUI()
        showQuestion()
        startTimer()

        // Жест для скрытия клавиатуры
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first { $0 is CAGradientLayer }?.frame = view.bounds
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Background
    private func setupBackground() {
        let gradient = CAGradientLayer()
        gradient.colors = colors
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
    }

    // MARK: - Timer
    private func startTimer() {
        updateTimerLabel()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { return }
            self.timeRemaining -= 1
            self.updateTimerLabel()
            if self.timeRemaining <= 0 {
                t.invalidate()
                self.forceFinishTest()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func updateTimerLabel() {
        let min = Int(timeRemaining) / 60
        let sec = Int(timeRemaining) % 60
        timerLabel.text = String(format: "⏰ %02d:%02d", min, sec)
    }

    // MARK: - UI Setup
    private func setupCollection() {
        questionNumbersCollection.backgroundColor = .clear
        questionNumbersCollection.delegate = self
        questionNumbersCollection.dataSource = self
        questionNumbersCollection.register(NumberCell.self, forCellWithReuseIdentifier: "NumberCell")
        view.addSubview(questionNumbersCollection)

        questionNumbersCollection.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionNumbersCollection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            questionNumbersCollection.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            questionNumbersCollection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            questionNumbersCollection.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupUI() {
        // таймер над вопросом
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        timerLabel.textColor = .white
        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: questionNumbersCollection.bottomAnchor, constant: 8),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // вопрос
        questionLabel.font = .systemFont(ofSize: 22, weight: .bold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        view.addSubview(questionLabel)

        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // кнопки select (макс 3)
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
                b.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 16),
                b.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                b.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                b.heightAnchor.constraint(equalToConstant: 50)
            ])

            last = b
            answerButtons.append(b)
        }

        // текстовый ответ
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .white
        textField.textColor = .black
        textField.placeholder = "Ваш ответ..."
        textField.isHidden = true
        textField.addDoneButtonOnKeyboard()
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])

        // кнопка "Продолжить"
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Questions flow
    private func showQuestion() {
        guard currentIndex < test.questions.count else {
            finishTest()
            return
        }

        let q = test.questions[currentIndex]
        questionLabel.text = q.text

        if q.type == .select, let opts = q.options {
            for (i, b) in answerButtons.enumerated() {
                if i < opts.count {
                    b.isHidden = false
                    b.setTitle(opts[i], for: .normal)
                } else {
                    b.isHidden = true
                }
            }
            textField.isHidden = true
            nextButton.isHidden = true
        } else {
            answerButtons.forEach { $0.isHidden = true }
            textField.isHidden = false
            nextButton.isHidden = false
            textField.text = attempt.answers.first(where: { $0.questionId == q.id })?.textAnswer ?? ""
        }

        questionNumbersCollection.reloadData()
        questionNumbersCollection.scrollToItem(
            at: IndexPath(item: currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    @objc private func answerTapped(_ sender: UIButton) {
        saveAnswer(selectedIndex: sender.tag, text: nil)
        currentIndex += 1
        showQuestion()
    }

    @objc private func nextTapped() {
        saveAnswer(selectedIndex: nil, text: textField.text)
        currentIndex += 1
        showQuestion()
    }

    private func saveAnswer(selectedIndex: Int?, text: String?) {
        let q = test.questions[currentIndex]
        let studentId = attempt.studentId
        let id = "\(q.id)_\(studentId)"

        let answer = StudentAnswer(
            id: id,
            questionId: q.id,
            studentId: studentId,
            testId: test.id,
            textAnswer: text,
            selectedIndex: selectedIndex,
            teacherScore: nil,
            teacherComment: nil,
            llmScore: nil,
            llmComment: nil,
            finalScore: nil
        )

        if let idx = attempt.answers.firstIndex(where: { $0.id == id }) {
            attempt.answers[idx] = answer
        } else {
            attempt.answers.append(answer)
        }
    }

    // MARK: - Finish
    private func finishTest() {
        timer?.invalidate()
        timer = nil

        Task {
            do {
                try await DependencyInjection.shared.answerService.submitAttempt(attempt)
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Тест завершён",
                        message: "Ответы отправлены учителю ✅",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { _ in
                        self.onFinish(self.attempt.answers.count)
                    }))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Ошибка",
                        message: "Не удалось отправить ответы",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Ок", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func forceFinishTest() {
        let studentId = attempt.studentId
        for q in test.questions {
            let id = "\(q.id)_\(studentId)"
            if attempt.answers.first(where: { $0.id == id }) == nil {
                attempt.answers.append(
                    StudentAnswer(
                        id: id,
                        questionId: q.id,
                        studentId: studentId,
                        testId: test.id,
                        textAnswer: nil,
                        selectedIndex: nil,
                        teacherScore: nil,
                        teacherComment: nil,
                        llmScore: nil,
                        llmComment: nil,
                        finalScore: nil
                    )
                )
            }
        }
        finishTest()
    }
}

// MARK: - Collection
extension DragonTestViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        test.questions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCell", for: indexPath) as! NumberCell
        cell.configure(number: indexPath.item + 1, isCurrent: indexPath.item == currentIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentIndex = indexPath.item
        showQuestion()
    }
}

// MARK: - NumberCell
private final class NumberCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 2
        contentView.layer.borderColor = UIColor.white.cgColor
        contentView.backgroundColor = .clear

        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white

        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(number: Int, isCurrent: Bool) {
        label.text = "\(number)"
        contentView.backgroundColor = isCurrent ? UIColor.systemBlue : UIColor.clear
    }
}
