//  ScorePill.swift
//  DragonTest

import UIKit

final class ScorePill: UIView {

    // MARK: - UI
    private let bg = CAGradientLayer()
    private let label = UILabel()

    // MARK: - Init (цветная плашка)
    init(color: UIColor) {
        super.init(frame: .zero)
        commonInit()
        applyColor(color)
    }

    // MARK: - Доп. init (если где-то используешь заголовочную плашку)
    convenience init(title: String) {
        self.init(color: UIColor.white.withAlphaComponent(0.16))
        label.text = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func commonInit() {
        layer.cornerRadius = 16
        if #available(iOS 13.0, *) { layer.cornerCurve = .continuous }
        clipsToBounds = true

        bg.startPoint = CGPoint(x: 0, y: 0.5)
        bg.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(bg, at: 0)

        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bg.frame = bounds
    }

    // MARK: - Public
    func setText(_ text: String) { label.text = text }
    func set(value text: String) { setText(text) } // алиас для обратной совместимости

    func applyColor(_ color: UIColor) {
        // лёгкий градиент от цвета к чуть более тёмному оттенку
        let darker = color.darker(by: 0.16)
        bg.colors = [color.cgColor, darker.cgColor]
    }
}

// MARK: - Helpers
private extension UIColor {
    func darker(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        return UIColor(red: max(r - amount, 0),
                       green: max(g - amount, 0),
                       blue: max(b - amount, 0),
                       alpha: a)
    }
}
