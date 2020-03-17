import Vapor

//TODO: Add Documentation
public enum ReadTarget<M: CorvusModel> {
    case all
    case existent
    case trashed(KeyPath<M, M.Timestamp>)
}
