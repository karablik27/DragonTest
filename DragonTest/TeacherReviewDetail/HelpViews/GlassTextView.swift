//
//  GlassTextView.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit

final class GlassTextView: UIView, UITextViewDelegate {
    private let glass = FieldGlass()
    private let tv = UITextView()
    var onChange: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(glass)
        glass.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        tv.backgroundColor = .clear
        tv.textColor = .white
        tv.font = ResultStyle.commentFont
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        tv.delegate = self
        tv.keyboardDismissMode = .interactive
        tv.inputAccessoryView = makeDoneToolbar()

        addSubview(tv)
        tv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: topAnchor),
            tv.leadingAnchor.constraint(equalTo: leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: trailingAnchor),
            tv.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(text: String) { tv.text = text }
    func setEditable(_ editable: Bool) {
        tv.isEditable = editable
        tv.isSelectable = editable
    }

    func textViewDidChange(_ textView: UITextView) { onChange?(textView.text) }

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
