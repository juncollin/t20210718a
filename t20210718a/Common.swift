//
//  Common.swift
//  Common
//
//  Created by 有本淳吾 on 2021/07/18.
//

import Foundation
import RealityKit

internal extension Entity {
    
    func modifyMaterials(_ closure: (Material) throws -> Material) rethrows {
        try children.forEach { try $0.modifyMaterials(closure) }
        
        guard var comp = components[ModelComponent.self] as? ModelComponent else { return }
        comp.materials = try comp.materials.map { try closure($0) }
        components[ModelComponent.self] = comp
    }
    
    func set(_ modifier: CustomMaterial.GeometryModifier) throws {
        try modifyMaterials { try CustomMaterial(from: $0, geometryModifier: modifier) }
    }
    
    func set(_ shader: CustomMaterial.SurfaceShader) throws {
        try modifyMaterials { try CustomMaterial(from: $0, surfaceShader: shader) }
    }
    
    
    /// Billboards the entity to the targetPosition which should be provided in world space.
    func billboard(targetPosition: SIMD3<Float>) {
        look(at: targetPosition, from: position(relativeTo: nil), relativeTo: nil)
    }


}
