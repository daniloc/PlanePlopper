//
//  PersistedModel.swift
//  PlanePlopperDemo
//
//  Created by Danilo Campos on 2/28/24.
//

import Foundation
import SwiftData
import RealityKit

@Model
class PersistedModel: AnchorableModel {
        
    var timestamp: Date
    var worldAnchorID: UUID?
    
    var debugDescription: String {
        return self.timestamp.debugDescription
    }
    
    @Transient var renderContent: RealityKit.Entity? = .init()
    
    @MainActor
    func updateRenderContent(_ entity: RealityKit.Entity?) {
        if let entity {
            self.renderContent?.addChild(entity)
        }
    }
    
    func loadContent() {
        Task {
            let placeholder = try? await ModelEntity(named: "Placeholder")
            await updateRenderContent(placeholder)
        }
    }
    
    init(timestamp: Date = .now) {
        self.timestamp = timestamp
        self.renderContent = .init()
        
        loadContent()
    }
}

