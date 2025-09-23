//
//  DragonCache.swift
//  DragonTest
//
//  Created by Карабельников Степан on 17.09.2025.
//

import Foundation
import RealityKit

final class DragonCache {
    private var storage: [DragonKind: Entity] = [:]
    private var preloaded = false
    
    init() {}

    
    @MainActor
    func preload() async {
        guard !preloaded else { return }
        for kind in DragonKind.allCases {
            if storage[kind] == nil {
                do {
                    let entity = try await Entity(named: kind.fileName)
                    storage[kind] = entity
                } catch {
                    print("Не удалось загрузить \(kind.fileName): \(error)")
                }
            }
        }
        preloaded = true
    }

    func clone(for kind: DragonKind, scale: SIMD3<Float>) -> Entity? {
        guard let base = storage[kind] else { return nil }
        let copy = base.clone(recursive: true)
        copy.scale = scale
        copy.position = [0, -0.05, 0]
        return copy
    }

    func loopFirstAnimation(on entity: Entity, in scene: Scene) {
        if let anim = entity.availableAnimations.first {
            entity.playAnimation(anim, transitionDuration: 0.2, startsPaused: false)
            _ = scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity) { [weak entity] _ in
                entity?.playAnimation(anim, transitionDuration: 0.15, startsPaused: false)
            }
        }
    }
}
