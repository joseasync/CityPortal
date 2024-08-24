//
//  ImmersiveView.swift
//  CityPortal
//
//  Created by Jose Cruz on 15/08/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
struct ImmersiveView: View {
    
    @State private var box = Entity() //To store the box
    
    var body: some View {
        // Add the initial RealityKit content
        RealityView { content in
            if let scene = try? await Entity(named: "CityPortalScene", in: realityKitContentBundle) {
                content.add(scene)
                setupBox(in: scene)
                await setupWorldsAndPortals(scene: scene)
            }
        }
        .gesture(dragGesture)
    }
    
    //Create the box and set the position
    private func setupBox(in scene: Entity) {
        guard let box = scene.findEntity(named: "Box") else {
            fatalError("Box entity not found")
        }
        self.box = box
        box.position = [0, 1.5, -2]
        box.scale *= [0.4, 0.8, 0.4]
        box.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        box.generateCollisionShapes(recursive: true)
        box.components.set(GroundingShadowComponent(castsShadow: true))
    }
    
    private func setupWorldsAndPortals(scene: Entity) async {
            let worldConfigurations: [(name: String, rotation: simd_quatf)] = [
                ("skybox1", simd_quatf(angle: .pi / -1.8, axis: [0, 1, 0])),
                ("skybox2", simd_quatf(angle: .pi / 1.3, axis: [0, 1, 0])),
                ("skybox3", simd_quatf(angle: .pi, axis: [0, 1, 0])),
                ("skybox4", simd_quatf(angle: -.pi/2.2, axis: [0, 1, 0]))
            ]
            
            for (index, config) in worldConfigurations.enumerated() {
                let world = Entity()
                world.components.set(WorldComponent())
                
                //Create the Sphere and add it to the world > scene
                let skybox = await createSkyboxEntity(texture: config.name, sphereRotation: config.rotation)
                world.addChild(skybox)
                scene.addChild(world)
                
                let portal = createPortal(target: world)
                scene.addChild(portal)
                
                //Set portal to the 3D archor
                let anchorName = "AnchorPortal\(index + 1)"
                guard let anchor = scene.findEntity(named: anchorName) else {
                    fatalError("Cannot find portal anchor: \(anchorName)")
                }
                anchor.addChild(portal)
                
                let portalRotation = calculatePortalRotation(index: index)
                portal.transform.rotation = portalRotation
            }
        }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToEntity(box)
            .onChanged { value in
                box.position = value.convert(value.location3D, from: .local, to: box.parent!)
            }
    }
    
    private func createSkyboxEntity(texture: String, sphereRotation: simd_quatf) async -> Entity {
        guard let resource = try? await TextureResource(named: texture) else {
            fatalError("Unable to load the skybox")
        }
        
        //Create the Material with the image source
        var material = UnlitMaterial()
        material.color = .init(texture: .init(resource))
        
        //Sphere
        let entity = Entity()
        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
        entity.scale *= .init(x: -1, y: 1, z: 1)
        entity.transform.rotation = sphereRotation
        
        return entity
    }
    
    private func createPortal(target: Entity) -> Entity {
        let portalMesh = MeshResource.generatePlane(width: 1, depth: 1)
        let portal = ModelEntity(mesh: portalMesh, materials: [PortalMaterial()])
        portal.components.set(PortalComponent(target: target))
        return portal
    }
    
    private func calculatePortalRotation(index: Int) -> simd_quatf {
        switch index {
        case 0:
            return simd_quatf(angle: .pi/2, axis: [1,0,0])
        case 1:
            return simd_quatf(angle: -.pi/2, axis: [1,0,0])
        case 2:
            let rotX = simd_quatf(angle: .pi/2, axis: [1,0,0])
            let rotY = simd_quatf(angle: -.pi/2, axis: [0,1,0])
            return rotY * rotX
        case 3:
            let rotX = simd_quatf(angle: .pi/2, axis: [1,0,0])
            let rotY = simd_quatf(angle: .pi/2, axis: [0,1,0])
            return rotY * rotX
        default:
            return simd_quatf()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
