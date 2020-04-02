import Corvus
import Fluent
import Foundation

final class Transaction: CorvusModel {

    static let schema = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "amount")
    var amount: Double

    @Field(key: "currency")
    var currency: String

    @Field(key: "date")
    var date: Date

    @Parent(key: "account_id")
    var account: Account

    init(
        id: UUID? = nil,
        amount: Double,
        currency: String,
        date: Date,
        accountID: Account.IDValue
    ) {
      self.id = id
      self.amount = amount
      self.currency = currency
      self.date = date
      self.$account.id = accountID
    }

    init() {}
}

struct CreateTransaction: Migration {

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Transaction.schema)
            .id()
            .field("amount", .double, .required)
            .field("currency", .string, .required)
            .field("date", .datetime, .required)
            .field("account_id", .uuid, .references(Account.schema, .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Transaction.schema).delete()
    }
}

extension Transaction: Equatable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        var result = lhs.amount == rhs.amount
            && lhs.currency == rhs.currency
            && lhs.$account.id == rhs.$account.id

        if let lhsID = lhs.id, let rhsID = rhs.id {
            result = result && lhsID == rhsID
        }

        return result
    }
}
