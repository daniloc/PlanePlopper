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
    
    enum Attachments {
        case action
    }
    
    @State var planePlopper: PlanePlopper
    var dataSource: ModelDataSource
        
    init(planePlopper: PlanePlopper, dataSource: ModelDataSource) {
        self.planePlopper = planePlopper
        planePlopper.dataSource = dataSource
        self.dataSource = dataSource
    }
    
    var body: some View {
        
        RealityView { content, attachments in
            
            content.add(planePlopper.utilityEntities.rootEntity)
            
            if let actionView = attachments.entity(for: Attachments.action) {
                planePlopper.utilityEntities.placementLocation.addChild(actionView)
                
                //Hover the attachment above the placement cursor, angled toward the user
                actionView.setPosition([0,0.15,0], relativeTo: planePlopper.utilityEntities.placementLocation)
                actionView.setOrientation(.init(angle: .deg2rad(-25), axis: [1,0,0]), relativeTo: planePlopper.utilityEntities.placementLocation)
            }
                
            Task {
                await planePlopper.runARKitSession()
            }
            
        } update: { content, attachments in
            
        } attachments: {
            Attachment(id: Attachments.action) {
                Button {
                    
                    planePlopper.anchor(dataSource.insert())

                    
                } label: {
                    Text("Plop Object")
                }
            }
        }
        .processUpdates(for: planePlopper)
    }
}
