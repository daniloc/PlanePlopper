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
    
    func shouldRemoveAnchor(with id: UUID) -> Bool {
        
        let remove = modelsMap[id] == nil
        
        print("Should remove anchor for \(id)? \(remove)")
        return remove
    }
    
    @MainActor
    func insert() -> PersistedModel {
        
        let newModel = PersistedModel()
        context.insert(newModel)
        
        return newModel
    }
    
    @MainActor
    func associate(_ model: AnchorableModel, with anchorID: UUID) {
        if let model = model as? PersistedModel {
            modelsMap[anchorID] = model
            model.worldAnchorID = anchorID
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
