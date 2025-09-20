//
//  VerticalSlideAnimator.swift
//  DragonTest
//
//  Created by Верховный Маг on 18.09.2025.
//

import UIKit

final class VerticalSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPush: Bool
    init(isPush: Bool) { self.isPush = isPush }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.55
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        guard
            let fromVC = ctx.viewController(forKey: .from),
            let toVC   = ctx.viewController(forKey: .to)
        else { ctx.completeTransition(false); return }

        let bounds = container.bounds

        if isPush {
            // toVC снизу, fromVC уезжает вверх
            toVC.view.frame = bounds.offsetBy(dx: 0, dy: bounds.height)
            container.addSubview(toVC.view)

            UIView.animate(withDuration: transitionDuration(using: ctx),
                           delay: 0,
                           usingSpringWithDamping: 0.92,
                           initialSpringVelocity: 0.6,
                           options: [.curveEaseInOut],
                           animations: {
                fromVC.view.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
                toVC.view.frame = bounds
            }, completion: { finished in
                fromVC.view.transform = .identity
                ctx.completeTransition(finished)
            })
        } else {
            // Pop: fromVC (тест) уезжает вниз, toVC (дракон) спускается сверху
            toVC.view.frame = bounds.offsetBy(dx: 0, dy: -bounds.height)
            container.insertSubview(toVC.view, belowSubview: fromVC.view)

            UIView.animate(withDuration: transitionDuration(using: ctx),
                           delay: 0,
                           usingSpringWithDamping: 0.92,
                           initialSpringVelocity: 0.6,
                           options: [.curveEaseInOut],
                           animations: {
                fromVC.view.frame = bounds.offsetBy(dx: 0, dy: bounds.height)
                toVC.view.frame = bounds
            }, completion: { finished in
                ctx.completeTransition(finished)
            })
        }
    }
}
