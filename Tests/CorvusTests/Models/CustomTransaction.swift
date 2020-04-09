import Corvus
import Fluent
import Foundation

final class CustomTransaction: CorvusModel {

    static let schema = "custom_transactions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "amount")
    var amount: Double

    @Field(key: "currency")
    var currency: String

    @Field(key: "date")
    var date: Date

    @Parent(key: "account_id")
    var account: CustomAccount

    init(
        id: UUID? = nil,
        amount: Double,
        currency: String,
        date: Date,
        accountID: CustomAccount.IDValue
    ) {
      self.id = id
      self.amount = amount
      self.currency = currency
      self.date = date
      self.$account.id = accountID
    }

    init() {}
}

struct CreateCustomTransaction: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(CustomTransaction.schema)
            .id()
            .field("amount", .double, .required)
            .field("currency", .string, .required)
            .field("date", .datetime, .required)
            .field("account_id", .uuid, .references(CustomAccount.schema, .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(CustomAccount.schema).delete()
    }
}

extension CustomTransaction: Equatable {
    static func == (lhs: CustomTransaction, rhs: CustomTransaction) -> Bool {
        var result = lhs.amount == rhs.amount
            && lhs.currency == rhs.currency
            && lhs.$account.id == rhs.$account.id

        if let lhsID = lhs.id, let rhsID = rhs.id {
            result = result && lhsID == rhsID
        }

        return result
    }
}
