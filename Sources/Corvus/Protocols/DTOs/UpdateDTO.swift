import Vapor

/// A protocol that defines Data Transfer Objects
/// that provide logic to update models on the database.
public protocol UpdateDTO: Decodable {
    
    /// The associated `CorvusModel` 
    associatedtype Element: CorvusModel
    
    /// Updates the old model and saves it back into the
    /// database.
    func patch(model: Element) throws
}
