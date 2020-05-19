import Corvus
import Fluent
import Foundation

final class SoloAccount: CorvusModel {

    static let schema = "solo_accounts"

    @ID
    var id: UUID? {
        didSet {
              if id != nil {
                  $id.exists = true
              }
          }
    }

    @Field(key: "name")
    var name: String
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }

    init() {}
}

struct CreateSoloAccount: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(SoloAccount.schema)
        .id()
        .field("name", .string, .required)
        .field("deleted_at", .date)
        .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(SoloAccount.schema).delete()
    }
}

extension SoloAccount: Equatable {
    static func == (lhs: SoloAccount, rhs: SoloAccount) -> Bool {
        var result = lhs.name == rhs.name
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}
