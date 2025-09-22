//
//  ProfileViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

import UIKit

final class ProfileViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return testNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return testNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        testTextField?.text = testNames[row]
    }
    
    
    // MARK: - Data
    private var testNames: [String] = []
    private var pickerView: UIPickerView?
    private weak var testTextField: UITextField?
    
    // MARK: - UI (основной экран)
    private let headerView = UIView()
    private let nameStack = UIStackView()
    private let bellButton = UIButton(type: .system)
    private let avatarImageView = UIImageView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    // MARK: - UI (правая панель)
    private let dimView = UIView()
    private let panelView = UIView()
    private let panelGrabber = UIView()
    private var panelLeadingConstraint: NSLayoutConstraint!
    private let panelWidth: CGFloat = 320
    private var panelIsVisible = false
    private var panelPanStartX: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addSudentsResultsSection()
        
        setupRightPanel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradient = view.layer.sublayers?.first(where: { $0.name == "backgroundGradient" }) as? CAGradientLayer {
            gradient.frame = view.bounds
        }
    }
    
    private func setupBackground() {
        view.layer.sublayers?
            .filter { $0.name == "backgroundGradient" }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.name = "backgroundGradient"
        gradient.colors = [
            UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1).cgColor,
            UIColor(red: 206/255, green: 204/255, blue: 195/255, alpha: 1).cgColor,
            UIColor(red: 0.45, green: 0.47, blue: 0.52, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.88, blue: 0.85, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 0.25, 0.65, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.frame      = view.bounds
        gradient.zPosition  = -1000
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = .white
        headerView.layer.cornerRadius = 32
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.shadowColor = UIColor.black.cgColor
        headerView.layer.shadowOpacity = 0.20
        headerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        headerView.layer.shadowRadius = 12

        let welcomeLabel = UILabel()
        welcomeLabel.text = "Welcome,"
        welcomeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        welcomeLabel.textColor = .secondaryLabel
        
        let nameLabel = UILabel()
        nameLabel.text = "Username"
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        
        nameStack.axis = .vertical
        nameStack.spacing = 2
        nameStack.addArrangedSubview(welcomeLabel)
        nameStack.addArrangedSubview(nameLabel)
        
        let bellImage = UIImage(systemName: "bell")
        bellButton.setImage(bellImage, for: .normal)
        bellButton.tintColor = .label
        bellButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bellButton.widthAnchor.constraint(equalToConstant: 28),
            bellButton.heightAnchor.constraint(equalToConstant: 28)
        ])
        bellButton.addTarget(self, action: #selector(didTapBell), for: .touchUpInside)
        
        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        let rightStack = UIStackView(arrangedSubviews: [bellButton, avatarImageView])
        rightStack.axis = .horizontal
        rightStack.spacing = 12
        rightStack.alignment = .center
        
        let mainStack = UIStackView(arrangedSubviews: [nameStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.distribution = .equalSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: -40),
            mainStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    // MARK: - Stats Section
    private func addStatsSection() {
        func makeStat(icon: String, value: String, title: String) -> UIView {
            let container = UIView()
            container.backgroundColor = .white
            container.layer.cornerRadius = 12
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.05
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4
            
            let avatar = UIImageView(image: UIImage(named: icon))
            avatar.contentMode = .scaleAspectFill
            avatar.clipsToBounds = true
            avatar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 25),
                avatar.heightAnchor.constraint(equalToConstant: 25)
            ])
            
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .secondaryLabel
            
            let stack = UIStackView(arrangedSubviews: [avatar, valueLabel, titleLabel])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            
            container.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                container.heightAnchor.constraint(equalToConstant: 100)
            ])
            
            return container
        }
        
        let dragons = makeStat(icon: "dragon.icon", value: "5", title: "Драконов")
        let tests = makeStat(icon: "📚", value: "12", title: "Тестов")
        let teachers = makeStat(icon: "👑", value: "3", title: "Учителя")
        let score = makeStat(icon: "⭐️", value: "87%", title: "Средний балл")
        
        let row1 = UIStackView(arrangedSubviews: [dragons, tests])
        row1.axis = .horizontal
        row1.spacing = 12
        row1.distribution = .fillEqually
        
        let row2 = UIStackView(arrangedSubviews: [teachers, score])
        row2.axis = .horizontal
        row2.spacing = 12
        row2.distribution = .fillEqually
        
        let grid = UIStackView(arrangedSubviews: [row1, row2])
        grid.axis = .vertical
        grid.spacing = 12
        
        contentStack.addArrangedSubview(grid)
    }
    
    // MARK: - Calendar Section
    private func addCalendarSection() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.05
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 260).isActive = true
        
        let segment = UISegmentedControl(items: ["Неделя", "Месяц"])
        segment.selectedSegmentIndex = 1
        
        let calendarLabel = UILabel()
        calendarLabel.text = "Календарь активности"
        calendarLabel.font = .systemFont(ofSize: 16, weight: .medium)
        calendarLabel.textAlignment = .center
        calendarLabel.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [segment, calendarLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        contentStack.addArrangedSubview(container)
    }
    
    // MARK: - Students Results Section (подиум)
    private func addSudentsResultsSection() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 450).isActive = true
     
        let titleLabel = UILabel()
        titleLabel.text = "Рейтинг прохождения тестов"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        testNames = ["Коллоквиум №1", "Коллоквиум №2", "Итоговый тест", "Практика iOS"]

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        self.pickerView = picker

        let textField = UITextField()
        textField.placeholder = "Выберите тест"
        textField.borderStyle = .roundedRect
        textField.inputView = picker
      
        let search = UISearchBar()
        search.placeholder = "Поиск по названию"
        
        let filterStack = UIStackView(arrangedSubviews: [titleLabel, textField, search])
        filterStack.axis = .vertical
        filterStack.spacing = 20
        
        func makeStudentView(place: Int, name: String, score: String, imageName: String) -> UIView {
            let column = UIView()

            let avatar = UIImageView(image: UIImage(named: imageName))
            avatar.contentMode = .scaleAspectFill
            avatar.layer.cornerRadius = 30
            avatar.clipsToBounds = true
            avatar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                avatar.widthAnchor.constraint(equalToConstant: 60),
                avatar.heightAnchor.constraint(equalToConstant: 60)
            ])

            let kind: DragonKind = {
                switch place {
                case 1: return .red
                case 2: return .green
                default: return .blue
                }
            }()

            let podium = UIView()
            podium.layer.cornerRadius = 12
            podium.clipsToBounds = true
            podium.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                podium.heightAnchor.constraint(equalToConstant: place == 1 ? 140 : 100),
                podium.widthAnchor.constraint(equalToConstant: 105)
            ])

            let gradient = GradientBackground.attach(to: podium, colors: kind.gradientColors)
            DispatchQueue.main.async { gradient.frame = podium.bounds }

            switch place {
            case 1:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(red: 0.99, green: 0.84, blue: 0.33, alpha: 1).cgColor
            case 2:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
            case 3:
                podium.layer.borderWidth = 2
                podium.layer.borderColor = UIColor(red: 0.80, green: 0.55, blue: 0.30, alpha: 1).cgColor
            default: break
            }

            let placeLabel = UILabel()
            placeLabel.text = {
                switch place {
                case 1: return "1 🏆"
                case 2: return "2 🥈"
                case 3: return "3 🥉"
                default: return "\(place)"
                }
            }()
            placeLabel.font = .systemFont(ofSize: 20, weight: .bold)
            placeLabel.textColor = .white
            placeLabel.textAlignment = .center

            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
            nameLabel.textColor = .white
            nameLabel.textAlignment = .center

            let scoreLabel = UILabel()
            scoreLabel.text = score
            scoreLabel.font = .systemFont(ofSize: 12)
            scoreLabel.textColor = .white
            scoreLabel.textAlignment = .center

            let vstack = UIStackView(arrangedSubviews: [placeLabel, nameLabel, scoreLabel])
            vstack.axis = .vertical
            vstack.alignment = .center
            vstack.spacing = 4
            vstack.translatesAutoresizingMaskIntoConstraints = false

            podium.addSubview(vstack)
            NSLayoutConstraint.activate([
                vstack.centerXAnchor.constraint(equalTo: podium.centerXAnchor),
                vstack.centerYAnchor.constraint(equalTo: podium.centerYAnchor)
            ])

            let stack = UIStackView(arrangedSubviews: [avatar, podium])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 8

            column.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: column.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: column.trailingAnchor),
                stack.topAnchor.constraint(equalTo: column.topAnchor),
                stack.bottomAnchor.constraint(equalTo: column.bottomAnchor)
            ])

            return column
        }

        let first  = makeStudentView(place: 1, name: "Maxwell", score: "7,120", imageName: "teacher1")
        let second = makeStudentView(place: 2, name: "Camelia", score: "6,500", imageName: "teacher2")
        let third  = makeStudentView(place: 3, name: "Wilson", score: "4,800", imageName: "teacher3")

        let podiumStack = UIStackView(arrangedSubviews: [second, first, third])
        podiumStack.axis = .horizontal
        podiumStack.alignment = .bottom
        podiumStack.distribution = .equalSpacing
        podiumStack.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [filterStack, podiumStack])
        mainStack.axis = .vertical
        mainStack.spacing = 40
        
        container.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        contentStack.addArrangedSubview(container)
    }

}

// MARK: - Правая панель уведомлений
private extension ProfileViewController {
    func setupRightPanel() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        dimView.alpha = 0
        dimView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hidePanel)))
        
        panelView.backgroundColor = .systemBackground
        panelView.layer.cornerRadius = 20
        panelView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        panelView.layer.shadowColor = UIColor.black.cgColor
        panelView.layer.shadowOpacity = 0.15
        panelView.layer.shadowOffset = CGSize(width: -2, height: 0)
        panelView.layer.shadowRadius = 8
        panelView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panelView)
        
        panelLeadingConstraint = panelView.leadingAnchor.constraint(equalTo: view.trailingAnchor)
        NSLayoutConstraint.activate([
            panelLeadingConstraint,
            panelView.topAnchor.constraint(equalTo: view.topAnchor),
            panelView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panelView.widthAnchor.constraint(equalToConstant: panelWidth)
        ])
        
        panelGrabber.backgroundColor = UIColor.secondaryLabel.withAlphaComponent(0.3)
        panelGrabber.layer.cornerRadius = 2
        
        let title = UILabel()
        title.text = "Уведомления"
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Закрыть", for: .normal)
        closeBtn.addTarget(self, action: #selector(hidePanel), for: .touchUpInside)
        
        let header = UIStackView(arrangedSubviews: [title, UIView(), closeBtn])
        header.axis = .horizontal
        header.alignment = .center
        
        let list = UIStackView()
        list.axis = .vertical
        list.spacing = 12
        
        let panelStack = UIStackView(arrangedSubviews: [panelGrabber, header, list])
        panelStack.axis = .vertical
        panelStack.spacing = 16
        panelStack.translatesAutoresizingMaskIntoConstraints = false
        panelView.addSubview(panelStack)
        NSLayoutConstraint.activate([
            panelGrabber.heightAnchor.constraint(equalToConstant: 4),
            panelGrabber.widthAnchor.constraint(equalToConstant: 36),
            panelStack.topAnchor.constraint(equalTo: panelView.safeAreaLayoutGuide.topAnchor, constant: 12),
            panelStack.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 16),
            panelStack.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -16),
            panelStack.bottomAnchor.constraint(lessThanOrEqualTo: panelView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        panelView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanelPan(_:))))
    }
    
    @objc func didTapBell() { showPanel() }
    
    private func showPanel(animated: Bool = true) {
        guard !panelIsVisible else { return }
        panelIsVisible = true
        panelLeadingConstraint.constant = -panelWidth
        let animations = {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 1
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) { animations() }
        } else {
            animations()
        }
    }
    
    @objc func hidePanel() {
        guard panelIsVisible else { return }
        panelIsVisible = false
        panelLeadingConstraint.constant = 0
        UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseIn]) {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0
        }
    }
    
    @objc func handlePanelPan(_ g: UIPanGestureRecognizer) {
        let translation = g.translation(in: view).x
        switch g.state {
        case .began:
            panelPanStartX = panelLeadingConstraint.constant
        case .changed:
            let next = min(0, panelPanStartX + translation)
            panelLeadingConstraint.constant = next
            let visibleRatio = 1 - abs(next) / panelWidth
            dimView.alpha = max(0, min(1, visibleRatio))
            view.layoutIfNeeded()
        case .ended, .cancelled:
            let velocityX = g.velocity(in: view).x
            let shouldClose = (velocityX > 500) || (panelLeadingConstraint.constant > -panelWidth * 0.5)
            if shouldClose { hidePanel() } else { showPanel() }
        default: break
        }
    }
}
