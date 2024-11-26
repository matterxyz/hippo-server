import XCTest
import DeviceCheck
import Hummingbird
import HummingbirdTesting

@testable import HummingbirdDeviceCheck

final class HummingbirdDeviceCheckTests: XCTestCase {
    func testDeviceCheckPasses() async throws {
        let app = try await testApp(deviceCheck: DeviceCheckClientPass())
        let expectedResponse = Response(status: .ok)

        try await app.test(.router) { client in
            try await client.execute(uri: "/test", method: .post, headers: [.deviceToken: "token", .contentType: "application/json"]) { response in
            XCTAssertEqual(expectedResponse.status, response.status)
            }
        }
    }
    func testDeviceCheckFailsNoToken() async throws {
        let app = try await testApp(deviceCheck: DeviceCheckClientPass())
        let expectedResponse = Response(status: .badRequest)

        try await app.test(.router) { client in
            try await client.execute(uri: "/test", method: .post, headers: [.contentType: "application/json"]) { response in
            XCTAssertEqual(expectedResponse.status, response.status)
            }
        }
    }
    func testDeviceCheckFailsVerification() async throws {
        let app = try await testApp(deviceCheck: DeviceCheckClientFailedVerify())
        let expectedResponse = Response(status: .badRequest)

        try await app.test(.router) { client in
            try await client.execute(uri: "/test", method: .post, headers: [.contentType: "application/json"]) { response in
            XCTAssertEqual(expectedResponse.status, response.status)
            }
        }
    }
}
