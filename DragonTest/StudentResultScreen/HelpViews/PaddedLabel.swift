//
//  PaddedLabel.swift
//  DragonTest
//
//  Created by Карабельников Степан on 27.09.2025.
//


import UIKit

final class PaddedLabel: UILabel {
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14) {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + contentInsets.left + contentInsets.right,
                      height: s.height + contentInsets.top + contentInsets.bottom)
    }
}
