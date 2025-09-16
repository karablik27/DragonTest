//
//  DragonARViewController.swift
//  DragonTest
//
//  Created by Карабельников Степан on 16.09.2025.
//

import UIKit
import RealityKit
import ARKit
import Combine

final class DragonARViewController: UIViewController {
    private var arView: ARView!
    private var anchor = AnchorEntity(world: [0, 0, -1.2])
    private var dragon: Entity?
    private var cancellables: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        arView.session.run(config)

        arView.scene.anchors.append(anchor)

        Task { await loadDragonAndPlayLooped() }
    }

    private func loadDragonAndPlayLooped() async {
        do {
            // Имя файла без .usdz
            let entity = try await Entity.load(named: "Dragon_Celebration")
            self.dragon = entity

            entity.scale = [0.7, 0.7, 0.7]
            entity.orientation = simd_quatf(angle: .pi/40, axis: [0, 1, 0])
            entity.position = [0, -50, -250]
            anchor.addChild(entity)

            guard let anim = entity.availableAnimations.first else {
                print("⚠️ Нет встроенных анимаций в Dragon_Celebration")
                return
            }

            // 1) первый запуск
            entity.playAnimation(anim, transitionDuration: 0.25, startsPaused: false)

            // 2) лупим через событие завершения
            arView.scene
                .subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity) { [weak self] _ in
                    guard let self = self, let dragon = self.dragon else { return }
                    dragon.playAnimation(anim, transitionDuration: 0.15, startsPaused: false)
                }
                .store(in: &cancellables)

        } catch {
            print("Не удалось загрузить Dragon_Celebration: \(error)")
        }
    }

    // MARK: Триггеры под UX
    func celebrate() {
        guard let dragon = dragon else { return }
        let base = dragon.transform
        var up = base; up.translation.y += 0.06
        dragon.move(to: up, relativeTo: dragon.parent, duration: 0.18, timingFunction: .easeOut)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            dragon.move(to: base, relativeTo: dragon.parent, duration: 0.18, timingFunction: .easeIn)
        }
    }

    func deny() {
        guard let dragon = dragon else { return }
        let base = dragon.orientation
        let left  = simd_quatf(angle:  0.18, axis: [0, 1, 0])
        let right = simd_quatf(angle: -0.36, axis: [0, 1, 0])

        dragon.setOrientation(base * left,  relativeTo: dragon.parent, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            dragon.setOrientation(base * right, relativeTo: dragon.parent, duration: 0.16)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            dragon.setOrientation(base * left,  relativeTo: dragon.parent, duration: 0.08)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            dragon.setOrientation(base, relativeTo: dragon.parent, duration: 0.08)
        }
    }
}

private extension Entity {
    func setOrientation(_ q: simd_quatf, relativeTo: Entity?, duration: TimeInterval) {
        move(to: Transform(scale: scale, rotation: q, translation: position),
             relativeTo: relativeTo, duration: duration, timingFunction: .easeInOut)
    }
}
