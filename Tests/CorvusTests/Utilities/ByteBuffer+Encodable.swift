import Vapor

extension ByteBuffer {
    init(string: String) {
        var buffer = ByteBufferAllocator().buffer(capacity: 0)
        buffer.writeString(string)
        self = buffer
    }
}

extension Encodable {
    func encode(_ encoder: JSONEncoder = JSONEncoder(), _ allocator: ByteBufferAllocator = .init()) throws -> ByteBuffer {
        try JSONEncoder().encodeAsByteBuffer(self, allocator: allocator)
    }
}
