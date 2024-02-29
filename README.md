# Easy API for Vision Pro persistent immersive object placement

https://github.com/daniloc/PlanePlopper/assets/213358/50be534d-fbde-4709-8b69-1038a4d5bc96

The primary way that visionOS augments reality is by detecting planes in the real world and allowing developers to attach objects to them.

PlanePlopper makes it fast and easy to get your project providing immersive RealityKit scenes where users can place objects on (horizonal) planes of their choosing.

## Installation

You download the project, have a look around, and then copy the PlanePlopper folder into your project. Adapt as needed. This is more adopting a puppy than it is subscribing to updates. My gut says Apple will provide their own implementation of this in visionOS 2.0. If I'm wrong and this ends up being long term useful, maybe it'll get SPM action.

## Usage

You'll write a data source object that conforms to this protocol:

```swift
protocol PlaneAnchoringDataSource {
    
    
    /// Provide a RealityKit entity corresponding to a given WorldAnchor
    /// - Parameter worldAnchor: A WorldAnchor the user has selected for placing a persisted object
    /// - Returns: a RealityKit entity to be rendered at the WorldAnchor's position
    func renderContentForAnchor(_ worldAnchor: WorldAnchor) -> Entity?
    
    
    /// Associate a WorldAnchor ID with a given model
    /// - Parameters:
    ///   - model: A recently anchored model
    ///   - id: A UUID corresponding to a WorldAnchor
    func associate(_ model: AnchorableModel, with anchorID: UUID)
    
    
    /// Determine if a previously set WorldAnchor should be removed
    /// - Parameter id: A WorldAnchor ID
    /// - Returns: A boolean to remove or keep the anchor
    func shouldRemoveAnchor(with id: UUID) -> Bool
    
}
```

How you persist your models is up to you, just make sure you can maintain an association between a given model instance and its WorldAnchor ID between launches.

Models should conform to `AnchorableModel`:

```swift
protocol AnchorableModel {
    
    /// RealityKit entity to be displayed at the model's selected WorldAnchor
    var renderContent: RealityKit.Entity? { get }
    
    var debugDescription: String { get }
}
```

A `RealityView` that adopts this approach looks like this:

```swift
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
```

# Acknowledgments

This approach aggresively simplifies and trims down Apple's [`ObjectPlacementExample`](https://developer.apple.com/documentation/visionos/placing-content-on-detected-planes) project. Their ARKit code is quite comprehensive, but also complex and tightly coupled to the persistence approach and content in the example app. PlanePlopper is simpler and hopefully more generalizable to your specific case. I wrote it because I needed code to plop things onto planes for a project I'm working on.
