//
//  GradientBackground.swift
//  DragonTest
//
//  Created by Карабельников Степан on 17.09.2025.
//

import UIKit

final class GradientBackground: CAGradientLayer {
    static func attach(to view: UIView, colors: [CGColor]) -> GradientBackground {
        view.layer.sublayers?
            .filter { $0.name == "backgroundGradient" }
            .forEach { $0.removeFromSuperlayer() }

        let g = GradientBackground()
        g.name = "backgroundGradient"
        g.colors = colors
        g.locations = [0.0, 0.55, 1.0]
        g.startPoint = CGPoint(x: 0, y: 0)
        g.endPoint   = CGPoint(x: 1, y: 1)
        g.frame      = view.bounds
        g.zPosition  = -1000
        view.layer.insertSublayer(g, at: 0)
        return g
    }
}
