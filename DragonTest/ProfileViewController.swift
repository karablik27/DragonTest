//
//  ProfileViewController.swift
//  DragonTest
//
//  Created by Alexandra Lazareva on 18.09.2025.
//

import UIKit

final class ProfileViewController: UIViewController {
    
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
        view.backgroundColor = .systemGray
        setupHeader()
        setupLayout()
        addStatsSection()
        addCalendarSection()
        addTopTeachersSection()
        
        setupRightPanel()
    }
    
    // MARK: - Header
    private func setupHeader() {
        headerView.backgroundColor = .white
        headerView.layer.cornerRadius = 32
        headerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.layer.masksToBounds = false
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
        bellButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        bellButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
        bellButton.addTarget(self, action: #selector(didTapBell), for: .touchUpInside)
        
        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
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
            mainStack.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: 8),
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
            
            let iconLabel = UILabel()
            iconLabel.text = icon
            iconLabel.font = .systemFont(ofSize: 26)
            
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = .systemFont(ofSize: 20, weight: .bold)
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 14)
            titleLabel.textColor = .secondaryLabel
            
            let stack = UIStackView(arrangedSubviews: [iconLabel, valueLabel, titleLabel])
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
        
        let dragons = makeStat(icon: "🐉", value: "5", title: "Драконов")
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
    
    // MARK: - Top Teachers Section
    private func addTopTeachersSection() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.05
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 300).isActive = true
        
        func makeTeacherView(place: Int, name: String, score: String, imageName: String, color: UIColor) -> UIView {
            let column = UIView()
            
            let avatar = UIImageView(image: UIImage(named: imageName))
            avatar.contentMode = .scaleAspectFill
            avatar.layer.cornerRadius = 30
            avatar.clipsToBounds = true
            avatar.translatesAutoresizingMaskIntoConstraints = false
            avatar.widthAnchor.constraint(equalToConstant: 60).isActive = true
            avatar.heightAnchor.constraint(equalToConstant: 60).isActive = true
            
            let podium = UIView()
            podium.backgroundColor = color
            podium.layer.cornerRadius = 12
            podium.translatesAutoresizingMaskIntoConstraints = false
            podium.heightAnchor.constraint(equalToConstant: place == 1 ? 140 : 100).isActive = true
            podium.widthAnchor.constraint(equalToConstant: 80).isActive = true
            
            let placeLabel = UILabel()
            placeLabel.text = "\(place)"
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
        
        let second = makeTeacherView(place: 2, name: "Camelia", score: "6,500", imageName: "teacher2", color: .systemBlue)
        let first  = makeTeacherView(place: 1, name: "Maxwell", score: "7,120", imageName: "teacher1", color: .systemRed)
        let third  = makeTeacherView(place: 3, name: "Wilson", score: "4,800", imageName: "teacher3", color: .systemIndigo)
        
        let hstack = UIStackView(arrangedSubviews: [second, first, third])
        hstack.axis = .horizontal
        hstack.alignment = .bottom
        hstack.distribution = .equalSpacing
        hstack.spacing = 12
        
        container.addSubview(hstack)
        hstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            hstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            hstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
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
        let dimTap = UITapGestureRecognizer(target: self, action: #selector(hidePanel))
        dimView.addGestureRecognizer(dimTap)
        
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
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanelPan(_:)))
        panelView.addGestureRecognizer(pan)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(hidePanel))
        swipe.direction = .right
        panelView.addGestureRecognizer(swipe)
    }
    
    @objc func didTapBell() {
        showPanel()
    }
    
    private func showPanel(animated: Bool = true) {
        guard !panelIsVisible else { return }
        panelIsVisible = true
        panelLeadingConstraint.constant = -panelWidth
        let animations = {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 1
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
                animations()
            }
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
            let visibleRatio = 1 - abs(next) / panelWidth // 0..1
            dimView.alpha = max(0, min(1, visibleRatio))
            view.layoutIfNeeded()
        case .ended, .cancelled:
            let velocityX = g.velocity(in: view).x
            let shouldClose = (velocityX > 500) || (panelLeadingConstraint.constant > -panelWidth * 0.5)
            if shouldClose {
                hidePanel()
            } else {
                showPanel()
            }
        default:
            break
        }
    }
}
