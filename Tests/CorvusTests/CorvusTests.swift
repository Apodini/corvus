import Corvus
import XCTVapor
import Fluent


class CorvusTests: XCTestCase {
    
    var app = Application(.testing)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app.databases.use(
            .sqlite(.memory),
            as: .init(string: "CorvusTest"),
            isDefault: true
        )
        
        app.middleware.use(CorvusToken.authenticator())
        app.middleware.use(CorvusUser.authenticator())
        
        app.migrations.add(CreateAccount())
        app.migrations.add(CreateTransaction())
        app.migrations.add(CreateSecureAccount())
        app.migrations.add(CreateSecureTransaction())
        app.migrations.add(CreateCorvusUser())
        app.migrations.add(CreateCorvusToken())
        
        app.migrations.add(CreateCustomUser())
        app.migrations.add(CreateCustomToken())
        app.migrations.add(CreateCustomAccount())
        app.migrations.add(CreateCustomTransaction())
     
        try app.autoMigrate().wait()
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
