//
//  DragonCache.swift
//  DragonTest
//
//  Created by Верховный Маг on 17.09.2025.
//

import Foundation
import RealityKit

final class DragonCache {
    static let shared = DragonCache()

    private var storage: [DragonKind: Entity] = [:]
    private var preloaded = false

    private init() {}

    @MainActor
    func preload() async {
        guard !preloaded else { return }
        for kind in DragonKind.allCases {
            if storage[kind] == nil {
                if let entity = try? await Entity.load(named: kind.fileName) {
                    storage[kind] = entity
                }
            }
        }
        preloaded = true
    }

    /// Клон сущности для отображения (можно безопасно добавлять в сцену)
    func clone(for kind: DragonKind, scale: SIMD3<Float>) -> Entity? {
        guard let base = storage[kind] else { return nil }
        let copy = base.clone(recursive: true)
        copy.scale = scale
        copy.position = [0, -0.05, 0]
        return copy
    }

    /// Зациклить первую доступную анимацию (если есть)
    func loopFirstAnimation(on entity: Entity, in scene: Scene) {
        if let anim = entity.availableAnimations.first {
            entity.playAnimation(anim, transitionDuration: 0.2, startsPaused: false)
            _ = scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity) { [weak entity] _ in
                entity?.playAnimation(anim, transitionDuration: 0.15, startsPaused: false)
            }
        }
    }
}
