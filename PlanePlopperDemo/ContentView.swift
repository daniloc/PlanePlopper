//
//  ContentView.swift
//  PlanePlopperDemo
//
//  Created by Danilo Campos on 2/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    var dataSource: ModelDataSource
    @State var planePlopper: PlanePlopper
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    

    func slider(value: Binding<Float>, label: String) -> some View {
        
        HStack {
            
            VStack {
                Text("\(label) offset: ")
                Text(String(format: "%.2f", value.wrappedValue))
            }
            .padding()
            
            Slider(value: value, in: -5...5, step: 0.25) {
                Text("\(label) offset")
            } minimumValueLabel: {
                Text("-5")
            } maximumValueLabel: {
                Text("5")
            }
            
        }
        .padding()
    }
    
    var body: some View {
        VStack {
            
            slider(value: $planePlopper.xOffset, label: "x")
            slider(value: $planePlopper.yOffset, label: "y")
            slider(value: $planePlopper.zOffset, label: "z")
            
            Toggle("Show Immersive Space", isOn: $showImmersiveSpace)
                .toggleStyle(.button)
                .padding(.top, 50)
            
            Button {
                dataSource.removeAll()
            } label: {
                Text("Remove All Objects")
            }
            .padding(.top, 32)

        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}
