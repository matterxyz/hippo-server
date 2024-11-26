import Foundation

public protocol ObjectStorage: Sendable {
    func exists(_ identifier: String) async throws -> Bool
    func getPresignedPost(for identifier: String) async throws -> (URL, [String: String])
    func getPresignedPut(for identifier: String) async throws -> URL
    func deleteObject(for identifier: String) async throws -> Void
    func makeObjectURL(for identifier: String) -> URL
}