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
    let plopper = PlanePlopper()
    
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
            ContentView(dataSource: dataSource, planePlopper: plopper)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(planePlopper: plopper, dataSource: dataSource)
        }

    }

}
