//
//  ScoreEditPillTeacher.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class ScoreEditPillTeacher: UIControl, UITextFieldDelegate {
    private let bg = CAGradientLayer()
    private let tf = UITextField()
    var onValueChanged: ((Int?) -> Void)?

    init(color: UIColor) {
        super.init(frame: .zero)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let darker = color.darker(by: 0.16)
        bg.startPoint = CGPoint(x: 0, y: 0.5)
        bg.endPoint   = CGPoint(x: 1, y: 0.5)
        bg.colors = [color.cgColor, darker.cgColor]
        layer.insertSublayer(bg, at: 0)

        tf.font = .systemFont(ofSize: 20, weight: .bold)
        tf.textAlignment = .center
        tf.textColor = .white
        tf.keyboardType = .numberPad
        tf.attributedPlaceholder = NSAttributedString(
            string: "—",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        )
        tf.delegate = self
        tf.inputAccessoryView = makeDoneToolbar()

        addSubview(tf)
        tf.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            tf.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            tf.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            tf.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tf.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); bg.frame = bounds }

    func set(value: Int?) { tf.text = value.map(String.init) }

    func setEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        tf.isEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool
    {
        let ns = textField.text as NSString? ?? ""
        let new = ns.replacingCharacters(in: range, with: string)
        if new.isEmpty { onValueChanged?(nil); return true }
        guard let v = Int(new), v >= 0, v <= 10 else { return false }
        onValueChanged?(v)
        return true
    }

    private func makeDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Готово", style: .done, target: self, action: #selector(endEdit))
        tb.items = [flex, done]
        return tb
    }
    @objc private func endEdit() { endEditing(true) }
}
