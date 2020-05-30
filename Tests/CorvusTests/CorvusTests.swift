import Corvus
import XCTVapor
import Fluent


class CorvusTests: XCTestCase {
    
    let app = Application(.testing)
    
    var account1 = Account(name: "Berzan's Wallet")
    var account2 = Account(name: "Paul's Wallet")
    var accountId1 = UUID()
    var accountId2 = UUID()
    
    var transaction1 = Transaction(
        amount: 40.0,
        currency: "EUR",
        date: Date()
    )
    var transaction2 = Transaction(
        amount: 40.0,
        currency: "USD",
        date: Date()
    )
    var transactionId1 = UUID()
    var transactionId2 = UUID()
    
    var user1 = TestUser(username: "berzan", password: "pass")
    var user2 = TestUser(username: "paul", password: "pass")
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "CorvusTest"),
            isDefault: true
        )
        
        app.middleware.use(CorvusToken.authenticator())
        app.middleware.use(CorvusUser.authenticator())
        
        app.migrations.add(
            CreateAccount(),
            CreateSoloAccount(),
            CreateTransaction(),
            CreateCorvusUser(),
            CreateCorvusToken()
        )
        
        try app.autoMigrate().wait()
        
        let corvusUser1 = CorvusUser(
            username: user1.username,
            password: try Bcrypt.hash(user1.password)
        )
        let corvusUser2 = CorvusUser(
            username: user2.username,
            password: try Bcrypt.hash(user2.password)
        )
        
        try corvusUser1.create(on: database()).wait()
        try corvusUser2.create(on: database()).wait()
        user1.id = corvusUser1.id
        user2.id = corvusUser2.id
        
        let userId1 = try XCTUnwrap(user1.id)
        let userId2 = try XCTUnwrap(user2.id)
        
        let corvusToken1 = CorvusToken(
            value: "kt3Lp9Aozk9JAwo13wueCw==",
            userID: userId1
        )
        let corvusToken2 = CorvusToken(
            value: "lgjksersr52452sdg23fsf==",
            userID: userId2
        )
        
        try corvusToken1.create(on: database()).wait()
        try corvusToken2.create(on: database()).wait()
        user1.token = corvusToken1.value
        user2.token = corvusToken2.value
        
        user1.id.map { account1.$user.id = $0 }
        user2.id.map { account2.$user.id = $0 }
        
        try account1.create(on: database()).wait()
        try account2.create(on: database()).wait()
        accountId1 = try XCTUnwrap(account1.id)
        accountId2 = try XCTUnwrap(account2.id)
        
        transaction1.$account.id = accountId1
        transaction2.$account.id = accountId2

        try transaction1.create(on: database()).wait()
        try transaction2.create(on: database()).wait()
        transactionId1 = try XCTUnwrap(transaction1.id)
        transactionId2 = try XCTUnwrap(transaction2.id)
    }
    
    override func tearDownWithError() throws {
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }
    
    func tester() throws -> XCTApplicationTester {
        try XCTUnwrap(app.testable())
    }
    
    func database() throws -> Database {
        try XCTUnwrap(self.app.db)
    }
}
