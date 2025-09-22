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

    private let modelName: String
    private let bgColors: [CGColor]

    init(modelName: String, backgroundColors: [CGColor]) {
        self.modelName = modelName
        self.bgColors  = backgroundColors
        super.init(nibName: nil, bundle: nil)
        title = "AR"
        tabBarItem = UITabBarItem(title: "AR", image: UIImage(systemName: "arkit"), tag: 1)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = GradientBackground.attach(to: view, colors: bgColors)

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
            let entity = try await Entity.load(named: modelName)
            self.dragon = entity

            entity.scale = [0.7, 0.7, 0.7]
            entity.orientation = simd_quatf(angle: .pi/40, axis: [0, 1, 0])
            entity.position = [0, -50, -250]
            anchor.addChild(entity)

            guard let anim = entity.availableAnimations.first else {
                print("⚠️ Нет встроенных анимаций в \(modelName)")
                return
            }

            entity.playAnimation(anim, transitionDuration: 0.25, startsPaused: false)

            arView.scene
                .subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity) { [weak self] _ in
                    guard let self = self, let dragon = self.dragon else { return }
                    dragon.playAnimation(anim, transitionDuration: 0.15, startsPaused: false)
                }
                .store(in: &cancellables)

        } catch {
            print("Не удалось загрузить \(modelName): \(error)")
        }
    }

    // MARK: Доп. жесты/эффекты
    func celebrate() {
        guard let dragon = dragon else { return }
        let base = dragon.transform
        var up = base; up.translation.y += 0.06
        dragon.move(to: up, relativeTo: dragon.parent, duration: 0.18, timingFunction: .easeOut)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            dragon.move(to: base, relativeTo: dragon.parent, duration: 0.18, timingFunction: .easeIn)
        }
    }
}
