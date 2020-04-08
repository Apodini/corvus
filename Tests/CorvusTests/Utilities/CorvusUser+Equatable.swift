import Corvus

extension CorvusUser: Equatable {
    
    public static func == (lhs: CorvusUser, rhs: CorvusUser) -> Bool {
        var result = lhs.username == rhs.username
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}
