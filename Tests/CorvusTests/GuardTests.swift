import Corvus
import Fluent
import FluentSQLiteDriver
import Vapor
import XCTVapor
import Foundation

var syncGuardCalled = false
var asyncGuardCalled = false

final class GuardTests: CorvusTests {
    
    struct SyncGuard: Guard {
        let username: String
        
        /// Type annotation is required!
        /// Otherwise Swift will not recognise this  value
        let error: Error = Abort(.badRequest)
        
        // swiftlint:disable:next identifier_name
        func ´guard´(req: Request) throws -> Bool {
            syncGuardCalled = true
            let user = try req.auth.require(CorvusUser.self)
            return user.username == username
        }
    }
    
    struct AsyncGuard: Guard {
        let minTransactions: Int
        
        init(min: Int) {
            minTransactions = min
        }
        
        /// Type annotation is required!
        /// Otherwise Swift will not recognise this value
        let error: Error = Abort(.badRequest)
        
        func asyncGuard(req: Request) -> EventLoopFuture<Bool> {
            asyncGuardCalled = true
            
            let userId = req.eventLoop.submit {
                try req.auth.require(CorvusUser.self).requireID()
            }
            
            let evaluator: (UUID) -> EventLoopFuture<Bool> = { userId in
                Account.query(on: req.db)
                .filter(\.$user.$id == userId)
                .with(\.$transactions)
                .first()
                .unwrap(or: self.error)
                .map { $0.transactions.count >= self.minTransactions }
            }

            return userId.flatMap(evaluator)
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let api = Api("api") {
            BasicAuthGroup<CorvusUser>("accounts") {
                GuardGroup("sync", guard: SyncGuard(username: user1.username)) {
                    ReadAll<Account>()
                }
                
                GuardGroup("asyncFailure", guard: AsyncGuard(min: 10)) {
                    ReadAll<Account>()
                }
                
                GuardGroup("asyncSuccess", guard: AsyncGuard(min: 0)) {
                    ReadAll<Account>()
                }
            }
        }

        try app.register(collection: api)
        
        syncGuardCalled = false
        asyncGuardCalled = false
    }

    func testGuardGroupSyncSuccess() throws {
        try tester()
        .test(
            .GET,
            "/api/accounts/sync",
            headers: ["Authorization": "\(user1.basicAuth())"]
        ) { res in
            let content = try res.content.decode([Account].self)
            XCTAssertEqual(content, [account1, account2])
            XCTAssert(syncGuardCalled)
        }
    }
    
    func testGuardGroupSyncFailure() throws {
        try tester()
        .test(
            .GET,
            "/api/accounts/sync",
            headers: ["Authorization": "\(user2.basicAuth())"]
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssert(syncGuardCalled)
        }
    }
    
    func testGuardGroupAsyncSuccess() throws {
        try tester()
        .test(
            .GET,
            "/api/accounts/asyncSuccess",
            headers: ["Authorization": "\(user1.basicAuth())"]
        ) { res in
            let content = try res.content.decode([Account].self)
            XCTAssertEqual(content, [account1, account2])
            XCTAssert(asyncGuardCalled)
        }
    }
    
    func testGuardGroupAsyncFailure() throws {
        try tester()
        .test(
            .GET,
            "/api/accounts/asyncFailure",
            headers: ["Authorization": "\(user1.basicAuth())"]
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssert(asyncGuardCalled)
        }
    }
}
