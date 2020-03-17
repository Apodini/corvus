import Foundation

//TODO: Add Documentation
public enum DeleteTarget<M: CorvusModel> {
    case existent
    case trashed(KeyPath<M, M.Timestamp>)

    var isTrash: Bool {
        if case .trashed(_) = self { return true }
        return false
    }
}
