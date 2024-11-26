import XCTest
@testable import Hippo

struct MockObjectStorage: ObjectStorage {
    static var existsReturn = true
    static var getPresignedPostReturn = (
        URL(string: "https://examplebucket.s3.amazonaws.com")!,
        ["acl": "public-read"]
    )
    static var getPresignedPutReturn = URL(string: "https://examplebucket.s3.amazon.aws.com")!
    static var makeObjectURLReturn = URL(string: "https://encrypted-assets.example.com/abcdefg")!

    func exists(_ identifier: String) async throws -> Bool {
        return Self.existsReturn
    }

    func getPresignedPost(for identifier: String) async throws -> (URL, [String: String]) {
        return Self.getPresignedPostReturn
    }

    func getPresignedPut(for identifier: String) async throws -> URL {
        return Self.getPresignedPutReturn
    }

    func deleteObject(for identifier: String) async throws -> Void {
        if identifier == "test/notFound" {
            throw HippoError.noObjectFound
        }
        return
    }

    func makeObjectURL(for: String) -> URL {
        return Self.makeObjectURLReturn
    }
}

final class HippoTests: XCTestCase {
    func getHippoInstance() -> Hippo {
        let hippo = Hippo(
            assetsHostName: "hippo-tests.example.com",
            assetsBucketName: "hippo-test-assets",
            metadataTable: "hippo-v1-tests",
            objectStorage: MockObjectStorage()
        )

        return hippo
    }

    func testHippo_Init() {
        let hippo = getHippoInstance()
        XCTAssertEqual(hippo.assetsHostName, "hippo-tests.example.com")
        XCTAssertEqual(hippo.assetsBucketName, "hippo-test-assets")
    }
    
    func testHippo_Init_CustomNames() {
        let hippo = Hippo(
            assetsHostName: "test.host.name",
            assetsBucketName: "test.bucket.name",
            metadataTable: "hippo-v1-tests",
            objectStorage: MockObjectStorage()
        )
        XCTAssertEqual(hippo.assetsHostName, "test.host.name")
        XCTAssertEqual(hippo.assetsBucketName, "test.bucket.name")
    }

    func testHippo_deleteAsset() async throws {
        let hippo = getHippoInstance()
        var errorThrown: Error? = nil
        do {
            try await hippo.deleteAsset(for: "test", with: "testKey")
        } catch {
            errorThrown = error
        }
        XCTAssertNil(errorThrown, "Error occured during deletion that should not have occured")
    }
    
    // TODO: Make better when S3 is implemented
    func testHippo_deleteAsset_notFound() async throws {
        let hippo = getHippoInstance()
        var errorThrown: Error? = nil
        do {
            try await hippo.deleteAsset(for: "test", with: "notFound")
        } catch {
            errorThrown = error
        }
        
        XCTAssertNotNil(errorThrown, "\(String(describing: errorThrown)) should not be nil")
        XCTAssertEqual(errorThrown as? HippoError, HippoError.noObjectFound)
    }
}
