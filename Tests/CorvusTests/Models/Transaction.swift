import Corvus
import Fluent

final class Transaction: CorvusModel {

    static let schema = "transactions"

    @ID(key: "id")
    var id: Int?

    @Field(key: "amount")
    var amount: Double

    @Field(key: "currency")
    var currency: String

    @Field(key: "description")
    var description: String?

    @Field(key: "date")
    var date: Date

    @Parent(key: "accountId")
    var account: Account

    init(
        id: Int? = nil,
        amount: Double,
        currency: String,
        description: String? = nil,
        date: Date,
        accountId: Account.IDValue
    ) {
      self.id = id
      self.amount = amount
      self.currency = currency
      self.description = description
      self.date = date
      self.$account.id = accountId
    }

    init() {}
}

extension Transaction {
    struct Migration: Fluent.Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("transactions")
                .field("id", .int, .identifier(auto: true))
                .field("amount", .double, .required)
                .field("currency", .string, .required)
                .field("description", .string)
                .field("date", .datetime, .required)
                .field("accountId", .int, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("transactions").delete()
        }
    }
}
