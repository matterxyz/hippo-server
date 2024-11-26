import XCTest
import HummingbirdTesting
import DeviceCheck
import Hummingbird
import HummingbirdDeviceCheck
import Hippo

@testable import HippoAPIv1

func makeTestApp(deviceCheck: any DeviceCheck, hippo: Hippo) async throws -> some ApplicationProtocol {
  let router = Router()
  router.add(middleware: LogRequestsMiddleware(.info))
  router.add(middleware: HummingbirdDeviceCheck(using: deviceCheck))

  HippoController(metadataTable: "metadata-table", assetsHostname: "test-hippo.example.com", assetsBucket: "assets").addRoutes(to: router.group("/v1"))

  return Application(router: router)
}

final class HippoControllerTests: XCTestCase {
  func testHippoController_noDeviceToken() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/v1/object?\(Parameter.clientReferenceOwner)=testReference&\(Parameter.clientReferenceID)=testID", method: .get, headers: [:], body: nil)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_getObject() async throws {
    let expectedResponse = Response(status: .seeOther, headers: [
      .location: "https://hippo-tests.example.com/v1/25b0482d-913d-455e-83c9-776855bf955b",
      .lastModified: "2022-03-12T23:45:12Z",
      .hippoPath: "/v1/25b0482d-913d-455e-83c9-776855bf955b"
    ])

    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/v1/object?\(Parameter.clientReferenceOwner)=testReference&\(Parameter.clientReferenceID)=testID", method: .get, headers: [
          .deviceToken: "token",
        ], body: nil)

      XCTAssertEqual(response.status, .seeOther)
      XCTAssertEqual(response.headers, expectedResponse.headers)
    }
  }

  func testHippoController_getObject_noClientOwner() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/v1/object?\(Parameter.clientReferenceID)=testID", method: .get, headers: [
          .deviceToken: "token",
        ], body: nil)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_getObject_noReferencedID() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/v1/object?\(Parameter.clientReferenceOwner)=testReference", method: .get, headers: [
          .deviceToken: "token",
        ], body: nil)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_getObject_badRequestError() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "/v1/object?\(Parameter.clientReferenceOwner)=errorCreds&\(Parameter.clientReferenceID)=errorCreds", method: .get, headers: [
          .deviceToken: "token",
        ], body: nil)
      XCTAssertEqual(response.status, .notFound)
    }
  }

  func testHippoController_createObject() async throws {
    let requestCreds = RequestUploadCredentials(clientReferenceOwner: "test", clientReferenceID: "test-id")
    let encodedCreds = try JSONEncoder().encode(requestCreds)
    let body = ByteBuffer(data: encodedCreds)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object", method: .post, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .ok)
    }
  }

  func testHippoController_createObject_noClientOwner() async throws {
    let requestCreds = RequestUploadCredentials(clientReferenceOwner: "", clientReferenceID: "test-id")
    let encodedCreds = try JSONEncoder().encode(requestCreds)
    let body = ByteBuffer(data: encodedCreds)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object", method: .post, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_createObject_noClientReferenceID() async throws {
    let requestCreds = RequestUploadCredentials(clientReferenceOwner: "test-owner", clientReferenceID: "")
    let encodedCreds = try JSONEncoder().encode(requestCreds)
    let body = ByteBuffer(data: encodedCreds)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))
    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object", method: .post, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_fetchObject() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/this-is-a-test", method: .get, headers: [.deviceToken : "token"], body: ByteBuffer())
      XCTAssertEqual(response.status, .seeOther)
      XCTAssertEqual(response.headers[.location], "https://test-hippo.example.com/v1/25b0482d-913d-455e-83c9-776855bf955b")
      XCTAssertEqual(response.headers[.lastModified], "2022-03-12T23:45:12Z")
    }
  }

  func testHippoController_fetchObject_fail() async throws {
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/testFailed", method: .get, headers: [.deviceToken : "token"], body: ByteBuffer())
      XCTAssertEqual(response.status, .notFound)
    }
  }

  func testHippoController_deleteObject() async throws {
    let objectSecret: String = "This-is-a-test-of-secret"
    let body = ByteBuffer(string: objectSecret)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/this-is-a-test", method: .delete, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .noContent)
    }
  }

  func testHippoController_deleteObject_fail_notFound() async throws {
    let objectSecret: String = "This-is-a-test-of-secret"
    let body = ByteBuffer(string: objectSecret)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/testFailed", method: .delete, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .notFound)
    }
  }

  func testHippoController_deleteObject_fail_emptyObejctSectret() async throws {
    let objectSecret: String = ""
    let body = ByteBuffer(string: objectSecret)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/this-is-a-test-no-object-sectret", method: .delete, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .badRequest)
    }
  }

  func testHippoController_deleteObject_fail_wrongObejctSectret() async throws {
    let objectSecret: String = "object secret does not match"
    let body = ByteBuffer(string: objectSecret)
    let app = try await makeTestApp(deviceCheck: MockDeviceCheckClient(), hippo: Hippo(assetsHostName: "test-hippo.example.com", assetsBucketName: "assets", metadataTable: "metadata-table", objectStorage: MockObjectStorage()))

    try await app.test(.router) { client in
      let response = try await client.execute(uri: "v1/object/this-is-a-test-no-object-sectret", method: .delete, headers: [.deviceToken : "token"], body: body)
      XCTAssertEqual(response.status, .forbidden)
    }
  }
}