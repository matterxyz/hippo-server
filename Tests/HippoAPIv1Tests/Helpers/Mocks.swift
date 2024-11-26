import Foundation
import Hippo
import DeviceCheck

struct MockDeviceCheckClient: DeviceCheck {
    static let isValid: @Sendable (String, any DeviceCheck) async throws -> ()  = { @Sendable (deviceToken: String, deviceCheck: DeviceCheck) async throws -> () in
        try await deviceCheck.check(deviceToken: deviceToken)
    }

    func check(deviceToken: String) async throws {
        return
    }
}

struct MockObjectStorage: ObjectStorage {
  func exists(_ identifier: String) async throws -> Bool {
    true
  }

  // TODO: Fill out with proper values
  func getPresignedPost(for identifier: String) async throws -> (URL, [String : String]) {
    (URL(string: "https://example.com")!, [:])
  }

  // TODO: Fill out with proper values
  func getPresignedPut(for identifier: String) async throws -> URL {
    URL(string: "https://example.com")!
  }

  func deleteObject(for identifier: String) async throws {
  }

  func makeObjectURL(for identifier: String) -> URL {
    return URL(string: "https://example.com/abcdefg")!
  }
}