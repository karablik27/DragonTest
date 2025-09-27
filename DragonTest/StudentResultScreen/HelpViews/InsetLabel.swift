//
//  InsetLabel.swift
//  DragonTest
//
//  Created by Верховный Маг on 27.09.2025.
//

import UIKit

final class InsetLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + contentInsets.left + contentInsets.right,
                      height: s.height + contentInsets.top + contentInsets.bottom)
    }
}
