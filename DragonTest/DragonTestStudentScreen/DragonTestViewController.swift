//
//  DragonTestViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 18.09.2025.
//

import UIKit

// MARK: - ViewController
final class DragonTestViewController: UIViewController, DragonTestViewProtocol {

    // MARK: - Presenter
    private var presenter: DragonTestPresenterProtocol!
    
    // MARK: - UI
    private let colors: [CGColor]
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let timerLabel = UILabel()
    private let progressLabel = UILabel()
    private let timerIcon = UIImageView(image: UIImage(systemName: "timer"))
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let questionNumbersCollection: UICollectionView
    private let onFinish: (Int) -> Void
    
    private let questionLabel = UILabel()
    private var answerButtons: [UIButton] = []
    private let answerTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        tv.layer.cornerRadius = 14
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .white
        tv.isHidden = true
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()
    private var answerTextViewHeight: NSLayoutConstraint!
    
    private let nextButton = UIButton(type: .system)
    
    private let hiddenTextField = UITextField(frame: .zero)
    
    // MARK: - Init
    init(test: Test, colors: [CGColor], onFinish: @escaping (Int) -> Void) {
        self.colors = colors
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.itemSize = CGSize(width: 40, height: 40)
        self.questionNumbersCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.questionNumbersCollection.showsHorizontalScrollIndicator = false
        self.onFinish = onFinish
        
        super.init(nibName: nil, bundle: nil)
        self.presenter = DragonTestPresenter(view: self, test: test)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupLayout()
        setupNextButton()
        setupKeyboardHandling()
        presenter.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = nextButton.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = nextButton.bounds
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        view.addSubview(hiddenTextField)
        hiddenTextField.becomeFirstResponder()
        hiddenTextField.resignFirstResponder()
        hiddenTextField.removeFromSuperview()
    }
    
    // MARK: - Keyboard
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        answerTextView.delegate = self
    }

    
    @objc private func keyboardWillShow(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let kbHeight = frame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = kbHeight + 20
        scrollView.verticalScrollIndicatorInsets.bottom = kbHeight
    }
    
    @objc private func keyboardWillHide(_ note: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() { view.endEditing(true) }
    
    // MARK: - Background
    private func setupBackground() {
        GradientBackground.attach(to: view, colors: colors)
    }
    
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        let timerCard = TestGlassCard(radius: 20)
        
        timerIcon.tintColor = .white
        timerIcon.preferredSymbolConfiguration = .init(pointSize: 18, weight: .medium)
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        timerLabel.textColor = .white
        timerLabel.text = "60:00"
        
        progressLabel.font = .systemFont(ofSize: 16, weight: .medium)
        progressLabel.textColor = .white
        progressLabel.text = "0 / 0"
        
        let headerStack = UIStackView(arrangedSubviews: [timerIcon, timerLabel, UIView(), progressLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 6
        
        progressBar.progress = 0.0
        progressBar.tintColor = .systemGreen
        progressBar.trackTintColor = UIColor.white.withAlphaComponent(0.1)
        
        let innerStack = UIStackView(arrangedSubviews: [headerStack, questionNumbersCollection, progressBar])
        innerStack.axis = .vertical
        innerStack.spacing = 12
        
        questionNumbersCollection.backgroundColor = .clear
        questionNumbersCollection.delegate = self
        questionNumbersCollection.dataSource = self
        questionNumbersCollection.register(NumberCell.self, forCellWithReuseIdentifier: "NumberCell")
        questionNumbersCollection.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        timerCard.addSubview(innerStack)
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: timerCard.topAnchor, constant: 16),
            innerStack.leadingAnchor.constraint(equalTo: timerCard.leadingAnchor, constant: 16),
            innerStack.trailingAnchor.constraint(equalTo: timerCard.trailingAnchor, constant: -16),
            innerStack.bottomAnchor.constraint(equalTo: timerCard.bottomAnchor, constant: -16)
        ])
        
        contentStack.addArrangedSubview(timerCard)
        
        let questionCard = TestGlassCard(radius: 20)
        let qStack = UIStackView()
        qStack.axis = .vertical
        qStack.spacing = 16
        
        let questionChip = ChipLabel()
        questionChip.text = "Вопрос"
        qStack.addArrangedSubview(questionChip)
        
        questionLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        
        let questionContainer = UIView()
        questionContainer.addSubview(questionLabel)
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: questionContainer.topAnchor, constant: 8),
            questionLabel.leadingAnchor.constraint(equalTo: questionContainer.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: questionContainer.trailingAnchor, constant: -16),
            questionLabel.bottomAnchor.constraint(equalTo: questionContainer.bottomAnchor, constant: -8)
        ])
        qStack.addArrangedSubview(questionContainer)
        for i in 0..<3 {
            let b = UIButton(type: .system)
            b.tag = i
            b.setTitleColor(.white, for: .normal)
            b.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            b.layer.cornerRadius = 10
            b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            b.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            b.heightAnchor.constraint(equalToConstant: 48).isActive = true
            answerButtons.append(b)
            qStack.addArrangedSubview(b)
        }
        let answerChip = ChipLabel()
        answerChip.text = "Ваш ответ"
        qStack.addArrangedSubview(answerChip)
        qStack.addArrangedSubview(answerTextView)
        answerTextViewHeight = answerTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        answerTextViewHeight.isActive = true
        answerTextView.autocorrectionType = .no
        answerTextView.spellCheckingType = .no
        answerTextView.autocorrectionType = .no
        answerTextView.spellCheckingType = .no
        answerTextView.smartInsertDeleteType = .no
        answerTextView.smartQuotesType = .no
        answerTextView.smartDashesType = .no
        answerTextView.keyboardType = .default
        
        questionCard.addSubview(qStack)
        qStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            qStack.topAnchor.constraint(equalTo: questionCard.topAnchor, constant: 20),
            qStack.leadingAnchor.constraint(equalTo: questionCard.leadingAnchor, constant: 20),
            qStack.trailingAnchor.constraint(equalTo: questionCard.trailingAnchor, constant: -20),
            qStack.bottomAnchor.constraint(equalTo: questionCard.bottomAnchor, constant: -20)
        ])
        contentStack.addArrangedSubview(questionCard)
        contentStack.addArrangedSubview(nextButton)
    }
    
    
    private func setupNextButton() {
        nextButton.setTitle("Продолжить", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextButton.layer.cornerRadius = 24
        nextButton.layer.masksToBounds = true
        nextButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(white: 0.2, alpha: 0.15).cgColor,
            UIColor(white: 0.1, alpha: 0.15).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 24
        gradient.frame = nextButton.bounds
        nextButton.layer.insertSublayer(gradient, at: 0)
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOpacity = 0.2
        nextButton.layer.shadowRadius = 10
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 5)
    }


    
    // MARK: - Actions
    @objc private func answerTapped(_ sender: UIButton) {
        presenter.answerSelected(index: sender.tag)
    }
    
    @objc private func nextTapped() {
        presenter.textAnswerSubmitted(text: answerTextView.text)
    }
    
    // MARK: - Protocol
    func showQuestion(text: String, options: [String]?, answerText: String?) {
        questionLabel.text = text
        
        if let opts = options {
            for (i, b) in answerButtons.enumerated() {
                if i < opts.count {
                    b.isHidden = false
                    b.setTitle(opts[i], for: .normal)
                } else {
                    b.isHidden = true
                }
            }
            answerTextView.isHidden = true
            nextButton.isHidden = true
        } else {
            answerButtons.forEach { $0.isHidden = true }
            answerTextView.isHidden = false
            nextButton.isHidden = false
            answerTextView.text = answerText ?? ""
            textViewDidChange(answerTextView)
        }
        
        progressLabel.text = "\(presenter.currentIndex + 1) / \(presenter.questionsCount)"
        progressBar.setProgress(Float(presenter.currentIndex + 1) / Float(presenter.questionsCount), animated: true)
        
        if presenter.currentIndex == presenter.questionsCount - 1 {
            nextButton.setTitle("Завершить тест", for: .normal)
        } else {
            nextButton.setTitle("Продолжить", for: .normal)
        }

        questionNumbersCollection.reloadData()
        questionNumbersCollection.scrollToItem(
            at: IndexPath(item: presenter.currentIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }

    
    
    func updateTimerLabel(text: String) {
        timerLabel.text = text
    }
    func showFinishAlert(answerCount: Int) {
        let alert = UIAlertController(
            title: "Тест завершён",
            message: "Молодец! 🎉 Ответы отправлены. Дожидайтесь автоматической проверки, она может занять несколько минут.\nКоличество ответов: \(answerCount)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default) { [weak self] _ in
                self?.onFinish(answerCount)
            })
        present(alert, animated: true)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TextView Delegate
extension DragonTestViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let fittingSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
        let size = textView.sizeThatFits(fittingSize)
        answerTextViewHeight.constant = max(120, size.height)

        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }

        if let range = textView.selectedTextRange {
            let caret = textView.caretRect(for: range.end)
            let rectInScroll = textView.convert(caret.insetBy(dx: 0, dy: -24), to: scrollView)
            scrollView.scrollRectToVisible(rectInScroll, animated: false)
        }
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if let range = textView.selectedTextRange {
            let caret = textView.caretRect(for: range.end)
            let rectInScroll = textView.convert(caret.insetBy(dx: 0, dy: -24), to: scrollView)
            scrollView.scrollRectToVisible(rectInScroll, animated: false)
        }
    }
}

// MARK: - Collection
extension DragonTestViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        presenter.questionsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCell", for: indexPath) as! NumberCell
        let isCurrent = indexPath.item == presenter.currentIndex
        let isAnswered = presenter.answered[indexPath.item]
        cell.configure(number: indexPath.item + 1, isCurrent: isCurrent, isAnswered: isAnswered)
        return cell
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenter.questionTapped(at: indexPath.item)
    }
}
