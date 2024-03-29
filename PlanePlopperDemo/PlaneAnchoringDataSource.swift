//
//  PlaneAnchoringDataSource.swift
//  Phasecrafter
//
//  Created by Danilo Campos on 2/22/24.
//

import Foundation
import RealityKit
import ARKit
import SwiftData

class ModelDataSource: PlaneAnchoringDataSource {
    
    let context: ModelContext
    var modelsMap: [UUID:PersistedModel] = [:]
    
    init(context: ModelContext) {
        self.context = context
        
        let fetchDescriptor = FetchDescriptor<PersistedModel>()

        do {
            let modelObjects = try context.fetch(fetchDescriptor)

            modelObjects.forEach { model in
                
                if let uuid = model.worldAnchorID {
                    self.modelsMap[uuid] = model
                    model.loadContent()
                    print("Loaded \(uuid)")
                }
            }
            
            print("Loaded \(modelObjects.count) entities")
        } catch {
            print("Failed to load stored models.")
        }
    }
    
    func shouldRemoveEntity(for id: UUID) -> Bool {
        print("No entity found for \(id)")
        return modelsMap[id] == nil
    }
    
    @MainActor
    func insert() -> PersistedModel {
        
        let newModel = PersistedModel()
        context.insert(newModel)
        
        return newModel
    }
    
    @MainActor
    func insertInstance(_ entity: AnchorableEntity, id: UUID) {
        if let entity = entity as? PersistedModel {
            modelsMap[id] = entity
            entity.worldAnchorID = id
            save()
        }
     }
    
    func removeAll() {
        modelsMap.values.forEach { simulation in
        
            simulation.renderContent?.removeFromParent()
            context.delete(simulation)
        }
        
        modelsMap = [:]
        save()
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Error saving: \(error)")
        }
    }
    
    func renderContentForAnchor(_ worldAnchor: WorldAnchor) -> Entity? {
        
        let source = modelsMap[worldAnchor.id]
        let renderContent = source?.renderContent
        
        return renderContent
        
    }
    
}
