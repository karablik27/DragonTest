//
//  DragonPreviewView.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import UIKit
import RealityKit

final class DragonPreviewView: UIView {
    private let arView = ARView(frame: .zero)
    private var modelAnchor: AnchorEntity?

    override init(frame: CGRect) {
        super.init(frame: frame)

        arView.automaticallyConfigureSession = false
        arView.cameraMode = .nonAR
        arView.environment.background = .color(.clear)
        arView.backgroundColor = .clear
        arView.isOpaque = false

        // Камера немного сверху
        let cam = PerspectiveCamera()
        let camAnchor = AnchorEntity(world: .zero)
        camAnchor.addChild(cam)
        arView.scene.addAnchor(camAnchor)
        cam.look(at: [0, 100, 0], from: [0, 110, 180], relativeTo: nil)

        // Свет
        let sun = DirectionalLight()
        sun.light.intensity = 2200
        sun.light.color = .white
        let sunAnchor = AnchorEntity(world: [0, 1, 1])
        sunAnchor.addChild(sun)
        arView.scene.addAnchor(sunAnchor)

        arView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arView)
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: trailingAnchor),
            arView.topAnchor.constraint(equalTo: topAnchor),
            arView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        backgroundColor = .clear
        clipsToBounds = false
    }

    required init?(coder: NSCoder) { fatalError() }

    func display(kind: DragonKind, scale: SIMD3<Float>) {
        if let a = modelAnchor { arView.scene.removeAnchor(a) }
        guard let entity = DragonCache.shared.clone(for: kind, scale: scale) else { return }

        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        modelAnchor = anchor

        DragonCache.shared.loopFirstAnimation(on: entity, in: arView.scene)
    }

    func celebrateBounce() {
        guard let e = modelAnchor?.children.first else { return }
        let base = e.transform
        var up = base; up.translation.y += 0.06
        e.move(to: up, relativeTo: e.parent, duration: 0.18, timingFunction: .easeOut)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            e.move(to: base, relativeTo: e.parent, duration: 0.18, timingFunction: .easeIn)
        }
    }
}
