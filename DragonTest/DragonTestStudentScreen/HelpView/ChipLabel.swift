//
//  ChipLabel.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//

import UIKit


// MARK: - Chip Label
final class ChipLabel: UILabel {
    private let insets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 16, weight: .semibold)
        textColor = .black
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.masksToBounds = true
        textAlignment = .center
    }

    required init?(coder: NSCoder) { fatalError() }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
