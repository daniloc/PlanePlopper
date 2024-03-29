//
//  PlanePlopper.swift
//
//  Created by Danilo Campos on 2/17/24.
//

/// Purpose: Manage the relationships between persisted WorldAnchors and the app's persisted data. Adds and removes entities from a RealityView, by querying data source for an entity per WorldAnchor id.

import Foundation
import RealityKit
import ARKit
import SwiftUI

/// Implement a data source to interact with your persistence strategy
protocol PlaneAnchoringDataSource {

    func renderContentForAnchor(_ worldAnchor: WorldAnchor) -> Entity?
    func insertInstance(_ entity: AnchorableEntity, id: UUID)
    func shouldRemoveEntity(for id: UUID) -> Bool
    
}

/// Persisted data models should conform to AnchorableEntity and store worldAnchorID's between sessions/
protocol AnchorableEntity {
    
    var worldAnchorID: UUID? { get set }
    var renderContent: RealityKit.Entity? { get }

    var debugDescription: String { get }
}


@Observable
class PlanePlopper {
    
    /// This struct holds entities necessary for tracking user gaze, providing feedback, and placing entities at user-specified locations
    struct UtilityEntities {
        
        var rootEntity: Entity = .init()
        let deviceLocation: Entity = .init()
        let raycastOrigin: Entity = .init()
        let placementLocation: Entity = .init()
                
        init() {
            rootEntity.addChild(placementLocation)
            deviceLocation.addChild(raycastOrigin)
            
            // Angle raycasts 15 degrees down.
            let raycastDownwardAngle = 15.0 * (Float.pi / 180)
            raycastOrigin.orientation = simd_quatf(angle: -raycastDownwardAngle, axis: [1.0, 0.0, 0.0])
        }
    }
    
    var dataSource: PlaneAnchoringDataSource?
    
    private let worldTracking = WorldTrackingProvider()
    private let planeDetection = PlaneDetectionProvider()
    
    private var planeAnchorHandler: PlaneAnchorHandler
    private var arInterface: ARKitInterface
    
    private var worldAnchors: [UUID:WorldAnchor] = [:]

    
    var utilityEntities: UtilityEntities
    
    var deviceAnchorPresent = false
    var planeAnchorsPresent = false
    
    static private let placedObjectsOffsetOnPlanes: Float = 0.01
    
    /// When the user is gazing at a valid plane target, insert the placement cursor
    var planeToProjectOnFound = false {
        didSet {
            if planeToProjectOnFound {
                utilityEntities.rootEntity.addChild(utilityEntities.placementLocation)
            } else {
                utilityEntities.placementLocation.removeFromParent()
            }
        }
    }
    
    init() {
        
        let entities = UtilityEntities()
        self.utilityEntities = entities
        
        planeAnchorHandler = .init(rootEntity: entities.rootEntity)
        arInterface = .init()
        
        Task {
            let cursor = try await ModelEntity(named: "PlacementCursor")
            await utilityEntities.placementLocation.addChild(cursor)
        }
    }

    
    @MainActor
    func runARKitSession() async {
        await arInterface.beginSession(world: worldTracking, plane: planeDetection)
    }
    
    @MainActor
    func processDeviceAnchorUpdates() async {
        await run(function: self.queryAndProcessLatestDeviceAnchor, withFrequency: 90)
    }
    
    @MainActor
    func processWorldAnchorUpdates() async {
        for await anchorUpdate in worldTracking.anchorUpdates {
            process(anchorUpdate)
        }
    }
    
    @MainActor
    private func queryAndProcessLatestDeviceAnchor() async {
        // Device anchors are only available when the provider is running.
        guard worldTracking.state == .running else { return }
        
        let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())

        deviceAnchorPresent = deviceAnchor != nil
        planeAnchorsPresent = !planeAnchorHandler.planeAnchors.isEmpty
        
        guard let deviceAnchor, deviceAnchor.isTracked else { return }
        
        await updatePlacementLocation(deviceAnchor)
    }
    
    @MainActor
    private func updatePlacementLocation(_ deviceAnchor: DeviceAnchor) async {
        utilityEntities.deviceLocation.transform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        let originFromUprightDeviceAnchorTransform = deviceAnchor.originFromAnchorTransform.gravityAligned
        
        // Determine a placement location on planes in front of the device by casting a ray.
        
        // Cast the ray from the device origin.
        let origin: SIMD3<Float> = utilityEntities.raycastOrigin.transformMatrix(relativeTo: nil).translation
    
        // Cast the ray along the negative z-axis of the device anchor, but with a slight downward angle.
        // (The downward angle is configurable using the `raycastOrigin` orientation.)
        let direction: SIMD3<Float> =  -utilityEntities.raycastOrigin.transformMatrix(relativeTo: nil).zAxis
        
        // Only consider raycast results that are within 0.2 to 3 meters from the device.
        let minDistance: Float = 0.2
        let maxDistance: Float = 3
        
        // Only raycast against horizontal planes.
        let collisionMask = PlaneAnchor.allPlanesCollisionGroup

        var originFromPointOnPlaneTransform: float4x4? = nil
        if let result = utilityEntities.rootEntity.scene?.raycast(origin: origin, direction: direction, length: maxDistance, query: .nearest, mask: collisionMask)
                                                  .first, result.distance > minDistance {
            if result.entity.components[CollisionComponent.self]?.filter.group != PlaneAnchor.verticalCollisionGroup {
                // If the raycast hit a horizontal plane, use that result with a small, fixed offset.
                originFromPointOnPlaneTransform = originFromUprightDeviceAnchorTransform
                originFromPointOnPlaneTransform?.translation = result.position + [0.0, Self.placedObjectsOffsetOnPlanes, 0.0]
            }
        }
        
        if let originFromPointOnPlaneTransform {
            utilityEntities.placementLocation.transform = Transform(matrix: originFromPointOnPlaneTransform)
            planeToProjectOnFound = true
        }
    }
    
    func processPlaneDetectionUpdates() async {
        for await anchorUpdate in planeDetection.anchorUpdates {
            await planeAnchorHandler.process(anchorUpdate)
        }
    }
    
    @MainActor
    func placeEntity(_ entity: AnchorableEntity) {

        entity.renderContent?.position = utilityEntities.placementLocation.position
        entity.renderContent?.orientation = utilityEntities.placementLocation.orientation
        
        Task {
            await attachEntityToWorldAnchor(entity)
        }
    }
    
    @MainActor
    func run(function: () async -> Void, withFrequency hz: UInt64) async {
        while true {
            if Task.isCancelled {
                return
            }
            
            // Sleep for 1 s / hz before calling the function.
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }
            
            await function()
        }
    }
    
    @MainActor
    func process(_ anchorUpdate: AnchorUpdate<WorldAnchor>) {
        
        print("Handling anchor update: \(anchorUpdate.anchor.id)")
        
        let anchor = anchorUpdate.anchor
        
        if anchorUpdate.event != .removed {
            worldAnchors[anchor.id] = anchor
        } else {
            worldAnchors.removeValue(forKey: anchor.id)
        }
        
        switch anchorUpdate.event {
        case .added:
            // Check whether there’s a persisted object attached to this added anchor -
            // it could be a world anchor from a previous run of the app.
            // ARKit surfaces all of the world anchors associated with this app
            // when the world tracking provider starts.
            if let contentToRender = dataSource?.renderContentForAnchor(anchor) {
                contentToRender.position = anchor.originFromAnchorTransform.translation
                contentToRender.orientation = anchor.originFromAnchorTransform.rotation
                contentToRender.isEnabled = anchor.isTracked
                utilityEntities.rootEntity.addChild(contentToRender)
            } else {
                if dataSource?.shouldRemoveEntity(for: anchor.id) == true {
                    Task {
                        // Immediately delete world anchors for which no placed object is known.
                        print("No object is attached to anchor \(anchor.id) - it can be deleted.")
                        await removeAnchorWithID(anchor.id)
                    }
                }
            }
            fallthrough
        case .updated:
            // Keep the position of placed objects in sync with their corresponding
            // world anchor, and hide the object if the anchor isn’t tracked.
            if let object = dataSource?.renderContentForAnchor(anchor) {
                object.position = anchor.originFromAnchorTransform.translation
                object.orientation = anchor.originFromAnchorTransform.rotation
                object.isEnabled = anchor.isTracked
                utilityEntities.rootEntity.addChild(object)
            }
        case .removed:
            // Remove the placed object if the corresponding world anchor was removed.
            dataSource?.renderContentForAnchor(anchor)?.removeFromParent()
        }
    }   
    
    @MainActor
    func attachEntityToWorldAnchor(_ entity: AnchorableEntity) async -> WorldAnchor? {
        // First, create a new world anchor and try to add it to the world tracking provider.
        guard let renderContent = entity.renderContent else {
            print("no render content")
            return nil
        }
        let anchor = WorldAnchor(originFromAnchorTransform: renderContent.transformMatrix(relativeTo: nil))
        
        do {
            dataSource?.insertInstance(entity, id: anchor.id)
            try await worldTracking.addAnchor(anchor)
        } catch {
            // Adding world anchors can fail, such as when you reach the limit
            // for total world anchors per app. Keep track
            // of all world anchors and delete any that no longer have
            // an object attached.
            
            if let worldTrackingError = error as? WorldTrackingProvider.Error, worldTrackingError.code == .worldAnchorLimitReached {
                print(
"""
Unable to place object "\(entity.debugDescription)". You’ve placed the maximum number of objects.
Remove old objects before placing new ones.
"""
                )
            } else {
                print("Failed to add world anchor \(anchor.id) with error: \(error).")
            }
            
            entity.renderContent?.removeFromParent()
            return nil
        }
        
        return anchor
    }
    
    func removeAnchorWithID(_ uuid: UUID) async {
        do {
            try await worldTracking.removeAnchor(forID: uuid)
        } catch {
            print("Failed to delete world anchor \(uuid) with error \(error).")
        }
    }
}
