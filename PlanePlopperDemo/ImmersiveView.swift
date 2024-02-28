//
//  ImmersiveView.swift
//  PlanePlopperDemo
//
//  Created by Danilo Campos on 2/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

struct ImmersiveView: View {
    
    @State var planePlopper: PlanePlopper
    var dataSource: ModelDataSource
    
    @Environment(\.modelContext) var modelContext
    
    init(planePlopper: PlanePlopper, dataSource: ModelDataSource) {
        self.planePlopper = planePlopper
        planePlopper.dataSource = dataSource
        self.dataSource = dataSource
    }

    func deg2rad(_ number: Float) -> Float {
        return number * .pi / 180
    }
    
    var body: some View {
        RealityView { content, attachments in
            
            content.add(planePlopper.utilityEntities.rootEntity)
            
            if let actionView = attachments.entity(for: "action") {
                planePlopper.utilityEntities.placementLocation.addChild(actionView)
                
                //Hover the attachment above the placement cursor, angled toward the user
                actionView.setPosition([0,0.15,0], relativeTo: planePlopper.utilityEntities.placementLocation)
                actionView.setOrientation(.init(angle: deg2rad(-25), axis: [1,0,0]), relativeTo: planePlopper.utilityEntities.placementLocation)
            }
                
            Task {
                await planePlopper.runARKitSession()
            }
            
        } update: { content, attachments in
            print("Update happened")
            
        } attachments: {
            Attachment(id: "action") {
                Button {
                    
                    
                    planePlopper.placeEntity(dataSource.insert())

                    
                } label: {
                    Text("Plop Object")
                }
            }
        }
        .task {
            // Monitor ARKit anchor updates once the user opens the immersive space.
            //
            // Tasks attached to a view automatically receive a cancellation
            // signal when the user dismisses the view. This ensures that
            // loops that await anchor updates from the ARKit data providers
            // immediately end.
            print("awaiting anchor updates")
            await planePlopper.processWorldAnchorUpdates()
        }
        .task {
            await planePlopper.processDeviceAnchorUpdates()
        }
        .task {
            await planePlopper.processPlaneDetectionUpdates()
        }
    }
}
