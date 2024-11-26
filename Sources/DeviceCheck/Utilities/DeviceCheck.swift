import Foundation

/// Required capabilities for device check
public protocol DeviceCheck: Sendable {
    static var isValid:  @Sendable (String, any DeviceCheck) async throws -> () { get }

    func check(deviceToken: String) async throws
}
