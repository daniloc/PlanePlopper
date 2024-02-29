# Easy API for Vision Pro persistent immersive object placement

PlanePlopper makes it fast and easy to get your project interacting with immersive RealityKit scenes where users can place objects on (horizonal) planes of their choosing.

## Installation

You download the project, have a look around, and then copy the PlanePlopper folder into your project. Adapt as needed. This is more adopting a puppy than it is subscribing to updates. My gut says Apple will provide their own implementation of this in visionOS 2.0. If this ends up being long term useful, maybe it'll get SPM action.

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
