//
//  LaunchViewController.swift
//  DragonTest
//
//  Created by Лазарева Александра on 27.09.2025.
//

import UIKit

final class LaunchViewController: UIViewController {
    
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "dragonPrev"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "DragonTest"
        lbl.font = .systemFont(ofSize: 28, weight: .bold)
        lbl.textColor = .white
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let gradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradient()
        setupLayout()
        animateLogo()
    }
    
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 2.39, green: 2.35, blue: 2.21, alpha: 0.2).cgColor,
            UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupLayout() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            logoImageView.widthAnchor.constraint(equalToConstant: 140),
            logoImageView.heightAnchor.constraint(equalToConstant: 140),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func animateLogo() {
        logoImageView.alpha = 0
        titleLabel.alpha = 0
        
        UIView.animate(withDuration: 1.0, animations: {
            self.logoImageView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.8) {
                self.titleLabel.alpha = 1
            }
        }
    }
}
