//
//  File.swift
//
//
//  Created by Nick Sloan on 1/2/24.
//

import App
import Hummingbird
import HummingbirdTesting
import XCTest
import DeviceCheck

@testable import Hippo

final class AppTests: XCTestCase {
    func testApp() async throws {
        let app = try await makeApplication(hostname: "127.0.01", port: 8600, testDeviceCheckClient: TestDeviceCheckClient())

        try await app.test(.router) { client in
            let response = try await client.executeRequest(uri: "/", method: .get, headers: [:], body: nil)
            XCTAssertEqual(response.status, .ok)
        }
    }
}
// Test device client to make a working application
struct TestDeviceCheckClient: DeviceCheck {
    static let isValid: @Sendable (String, any DeviceCheck) async throws -> ()  = { @Sendable (deviceToken: String, deviceCheck: DeviceCheck) async throws -> () in
        try await deviceCheck.check(deviceToken: deviceToken)
    }

    func check(deviceToken: String) async throws {
        return
    }
}
