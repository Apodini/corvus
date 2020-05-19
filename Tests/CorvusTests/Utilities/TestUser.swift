import Foundation
import Vapor
import XCTest

struct TestUser: Codable {
    
    var id: UUID?
    let username: String
    let password: String
    var token: String?
    
    func basicAuth() throws -> String {
        let credentials = try XCTUnwrap(
            "\(username):\(password)".data(using: .utf8)?.base64EncodedString()
        )
        return "Basic \(credentials)"
    }
    
    func bearerToken() throws -> String {
        "Bearer \(try XCTUnwrap(token))"
    }
}
