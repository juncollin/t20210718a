//
//  ViewController.swift
//  t20210718a
//
//  Created by 有本淳吾 on 2021/07/18.
//

import UIKit
import RealityKit
import Combine




struct YAxisBillboardComponent: Component {}
extension YAxisBillboardComponent: Codable {}
protocol HasYAxisBillboard where Self: Entity {}

extension HasYAxisBillboard where Self: Entity {
    var yAxisBillboard: YAxisBillboardComponent {
        get { return components[YAxisBillboardComponent.self] ?? YAxisBillboardComponent() }
        set { components[YAxisBillboardComponent.self] = newValue }
    }

    func rotate(lookAt: Transform) {
        guard let parent = self.parent else { return }
        // get camera world space position
        let cameraPosition = lookAt.translation
        var newTransform = transform

        // Y axis rotation towards lookAt in X-Z
        newTransform = newTransform.yAxisLookAtWorldSpacePoint(parentEntity: parent, worldSpaceAt: cameraPosition)

        // since this is a local transorm to this device, we
        // don't want it shipped across the network to other devices.
        // let them figure out their own transform
        self.withUnsynchronized {
            self.transform = newTransform
        }
    }
}

extension Transform {
    // yAxisLookAtWorldSpacePoint()
    // support for camera facing billboard which only rotates around the Y axis.  i.e. a glow texture around a vertical
    // object such as a bowling pin which is made to always face the camera
    func yAxisLookAtWorldSpacePoint(parentEntity: Entity, worldSpaceAt: SIMD3<Float>) -> Transform {

        // worldSpaceToParentSpace is the to-parent-space-from-world-space transfrorm (for us)
        let worldSpaceToParentSpace = parentEntity.transformMatrix(relativeTo: nil).inverse

        let lsTarget = worldSpaceToParentSpace * SIMD4<Float>(worldSpaceAt.x, worldSpaceAt.y, worldSpaceAt.z, 1.0)
        // local space position is transform.translation
        let position = translation
        let lsPosition = SIMD4<Float>(position.x, position.y, position.z, 1.0)
        let lsUpVector = SIMD4<Float>(0.0, 1.0, 0.0, 0.0)

//        var positionToTarget = lsTarget.xyz - lsPosition.xyz
        var positionToTarget = SIMD3<Float>(lsTarget.x, lsTarget.y, lsTarget.z) - SIMD3<Float>(lsPosition.x,lsPosition.y, lsPosition.z)

        positionToTarget.y = 0
        let zAxis = normalize(positionToTarget)

        // check if up vector and zAxis are same and so
        // cross product will not give good result
//        let cosAngle = abs(dot(lsUpVector.xyz, zAxis))
//        let xAxis = normalize(cross(lsUpVector.xyz, zAxis))

        let cosAngle = abs(dot(SIMD3<Float>(lsUpVector.x, lsUpVector.y, lsUpVector.z), zAxis))
        let xAxis = normalize(cross(SIMD3<Float>(lsUpVector.x, lsUpVector.y, lsUpVector.z), zAxis))


        if cosAngle >= (Float(1.0) - .ulpOfOne) {
//            os_log(.error, log: GameLog.general, "Error: up=(%s), z=(%s), cross is x=(%s)", "\(lsUpVector)", "\(zAxis)", "\(xAxis)")
        }
        let yAxis = cross(zAxis, xAxis)

        let matrix = float4x4(SIMD4<Float>(xAxis.x, xAxis.y, xAxis.z, 0),
                              SIMD4<Float>(yAxis.x, yAxis.y, yAxis.z, 0),
                              SIMD4<Float>(zAxis.x, zAxis.y, zAxis.z, 0),
                              SIMD4<Float>(lsPosition.x, lsPosition.y, lsPosition.z, 1))
        var transform = Transform(matrix: matrix)

//        let scale = UserSettings.glowScale
//        if scale != 1.0 {
//            transform.scale = SIMD3<Float>(repeating: scale)
//        }
        return transform
    }

}


class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    private var sceneEventsUpdateSubscription: Cancellable!

    
    func rotate(ent: Entity, lookAt: Transform) {
        guard let parent = ent.parent else { return }
        // get camera world space position
        let cameraPosition = lookAt.translation
        var newTransform = parent.transform

        // Y axis rotation towards lookAt in X-Z
        newTransform = newTransform.yAxisLookAtWorldSpacePoint(parentEntity: parent, worldSpaceAt: cameraPosition)

        // since this is a local transorm to this device, we
        // don't want it shipped across the network to other devices.
        // let them figure out their own transform
        ent.transform = newTransform
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Load the "Box" scene from the "Experience" Reality File
//        let boxAnchor = try! Experience.loadBox()
//
//        // Add the box anchor to the scene
//        arView.scene.anchors.append(boxAnchor)
        
        //let anchor = AnchorEntity()
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
        arView.scene.anchors.append(anchor)
        
        let planeModel = ModelEntity(
            mesh: .generatePlane(width: 0.5, height: 1.0), materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )

        let mtlLibrary = MTLCreateSystemDefaultDevice()!
          .makeDefaultLibrary()!

        do {
            let surfaceShader = CustomMaterial.SurfaceShader(
                named: "simpleSurface", in: mtlLibrary
            )
            try planeModel.modifyMaterials {
                var mat = try CustomMaterial(from: $0, surfaceShader: surfaceShader)
//                let tex = try TextureResource.load(named: "number1234.png")
                let tex = try TextureResource.load(named: "number13.png")
                mat.custom.texture = .init(tex)
                //try! MaterialColorParameter.texture(
//                    TextureResource.load(named: "number.png"))
                return mat
            }
        } catch {
            assertionFailure("Failed to set a custom shader \(error)")
        }
        
        planeModel.position = SIMD3<Float>(0.0, 0.0, -1.0)
//        planeModel.transform.rotation = simd_quatf(angle: .pi/2, axis: [0,0,1])
//        planeModel.look(at: arView.cameraTransform.translation, from: planeModel.position, upVector: [0,1,0], relativeTo: nil)
        rotate(ent: planeModel, lookAt: arView.cameraTransform)
//        rotate(ent: planeModel, lookAt: SIMD3<Float>(0.4,0.4,0.0))
        
        anchor.addChild(planeModel)
        
        let b = ModelEntity(
            mesh: .generateBox(size: 0.5),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        b.position = SIMD3<Float>(1.0, 0.0, -1.0)
        anchor.addChild(b)
        
        sceneEventsUpdateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [self] _ in
//            planeModel.billboard(targetPosition: arView.cameraTransform.translation)
//            planeModel.look(at: arView.cameraTransform.translation, from: planeModel.position, upVector: SIMD3(0.0,1.0,0.0), relativeTo: nil)
//            look(at: arView.cameraTransform, from: position(relativeTo: nil), relativeTo: nil)
            b.look(at: arView.cameraTransform.translation, from: b.position, relativeTo: nil)
            rotate(ent: planeModel, lookAt: arView.cameraTransform)

        }
    }
}
