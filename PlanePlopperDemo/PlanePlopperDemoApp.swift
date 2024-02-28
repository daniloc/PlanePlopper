//
//  PlanePlopperDemoApp.swift
//  PlanePlopperDemo
//
//  Created by Danilo Campos on 2/28/24.
//

import SwiftUI
import SwiftData

@main
struct PhasecrafterApp: App {
    
    let modelContainer: ModelContainer
    let dataSource: ModelDataSource
    
    init() {
        do {
            modelContainer = try ModelContainer(for: PersistedModel.self)
            dataSource = .init(context: modelContainer.mainContext)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataSource: dataSource)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(planePlopper: PlanePlopper(), dataSource: dataSource)
        }

    }

}
