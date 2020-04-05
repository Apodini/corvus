import Foundation

internal struct FieldCodingKey: CodingKey {

    var stringValue: String
    var intValue: Int?
    
    init(_ key: String) {
        self.stringValue = String(key.dropFirst())
    }
    
    init?(stringValue: String) {
        self.stringValue = String(stringValue.dropFirst())
    }
    
    // Function name can only start with a letter or underscore, not a number
    init?(intValue: Int) {
        nil
    }
}

internal protocol DecodableField {
    typealias Container = KeyedDecodingContainer<FieldCodingKey>
    func decodeValue(_ key: String, from container: Container) throws
}
