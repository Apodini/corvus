import Corvus
import Fluent
import FluentSQLiteDriver
import XCTVapor
import Foundation

final class SoftDeleteTests: CorvusTests {
    
    var acc1 = SoloAccount(name: "Delete1")
    var acc2 = SoloAccount(name: "Delete2")
    var accId1 = UUID()
    var accId2 = UUID()
        
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let accountParameter = Parameter<SoloAccount>().id
        
        let api = Api("api") {
            Group("accounts") {
                ReadAll<SoloAccount>()

                Group(accountParameter) {
                    ReadOne<SoloAccount>(accountParameter)
                    Delete<SoloAccount>(accountParameter)
                }
                
                Group("trash") {
                    Group(accountParameter) {
                        ReadOne<SoloAccount>(accountParameter, .trashed)
                        Delete<SoloAccount>(accountParameter, softDelete: true)
                        
                        Group("restore") {
                            Restore<SoloAccount>(accountParameter)
                        }
                    }
                    
                    ReadAll<SoloAccount>(.trashed)
                }
                
                Group("existing") {
                    Group(accountParameter) {
                        ReadOne<SoloAccount>(accountParameter, .existing)
                    }
                    
                    ReadAll<SoloAccount>(.existing)
                }

                Group("all") {
                    Group(accountParameter) {
                        ReadOne<SoloAccount>(accountParameter, .all)
                    }
                    
                    ReadAll<SoloAccount>(.all)
                }
            }
        }
        
        try acc1.create(on: database()).wait()
        try acc2.create(on: database()).wait()
        accId1 = try XCTUnwrap(acc1.id)
        accId2 = try XCTUnwrap(acc2.id)
        
        try app.register(collection: api)
    }
    
    func testRestore() throws {
        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accId1)") { res in
                XCTAssertEqual(res.status, .ok)
            }.test(.GET, "/api/accounts/\(accId1)") { res in
                XCTAssertEqual(res.status, .notFound)
            }.test(.PATCH, "/api/accounts/trash/\(accId1)/restore") { res in
                XCTAssertEqual(res.status, .ok)
            }.test(.GET, "/api/accounts/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }
    }
    
    func testReadAllTrashed() throws {
        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accId1)")
            .test(.GET, "/api/accounts") { res in
                let response = try res.content.decode([SoloAccount].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [acc2])
            }
            .test(.GET, "/api/accounts/existing") { res in
                let response = try res.content.decode([SoloAccount].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [acc2])
            }
            .test(.GET, "/api/accounts/all") { res in
                let response = try res.content.decode([SoloAccount].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [acc1, acc2])
            }
            .test(.GET, "/api/accounts/trash") { res in
                let response = try res.content.decode([SoloAccount].self)
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(response, [acc1])
            }
    }

    func testReadOneTrashed() throws {
        try tester()
            .test(.GET, "/api/accounts/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }.test(.GET, "/api/accounts/existing/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }.test(.DELETE, "/api/accounts/trash/\(accId1)")
            .test(.GET, "/api/accounts/existing/\(accId1)") { res in
                XCTAssertEqual(res.status, .notFound)
            }.test(.GET, "/api/accounts/all/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }.test(.GET, "/api/accounts/trash/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }
    }

    func testDeleteTrashed() throws {
        try tester()
            .test(.DELETE, "/api/accounts/trash/\(accId1)")
            .test(.GET, "/api/accounts/trash/\(accId1)") { res in
                let content = try res.content.decode(SoloAccount.self)
                XCTAssertEqual(content, acc1)
            }
            .test(.DELETE, "/api/accounts/\(accId1)")
            .test(.GET, "/api/accounts/trash/\(accId2)") { res in
                XCTAssertEqual(res.status, .notFound)
            }
    }
}
