//
//  TransitioningDelegate.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//


import UIKit

final class VerticalSlideTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private let isPush: Bool
    init(isPush: Bool) { self.isPush = isPush }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalSlideAnimator(isPush: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VerticalSlideAnimator(isPush: false)
    }
}
