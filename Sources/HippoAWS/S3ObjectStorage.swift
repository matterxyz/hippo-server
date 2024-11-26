import Foundation
import Hippo

public class S3ObjectStorage: ObjectStorage {

    private let aws: AWSWrapper
    private let bucket: String

    public init(aws: AWSWrapper = AWSWrapper(), bucket: String) {
        self.aws = aws
        self.bucket = bucket
    }

    private func getObjectKey(for identifier: String) -> String {
        return "\(identifier)"
    }

    public func exists(_ identifier: String) async throws -> Bool {
        let key = getObjectKey(for: identifier)
        let output = try? await aws.s3.headObject(.init(bucket: bucket, key: key))

        return output != nil
    }

    public func getPresignedPost(for identifier: String) async throws -> (URL, [String: String]) {
        let key = getObjectKey(for: identifier)
        let post = try await aws.s3.generatePresignedPost(
            key: key,
            bucket: bucket,
            fields: ["acl": "public-read"],
            conditions: [.match("acl", "public-read")],
            expiresIn: 3600.0
        )

        return (post.url, post.fields)
    }

    public func getPresignedPut(for identifier: String) async throws -> URL {
        var url = makeObjectURL(for: identifier)
        url = URL(string: url.absoluteString + "?x-amz-acl=public-read")!

        let signedURL = try await aws.s3.signURL(url: url, httpMethod: .PUT, expires: .minutes(5))

        return signedURL
    }

    public func makeObjectURL(for identifier: String) -> URL {
        guard let url = try? aws.s3.makeObjectURL(bucket: bucket, key: identifier) else {
            fatalError("URL construction failed")
        }

        return url
    }

    public func deleteObject(for identifier: String) async throws {
        let key = getObjectKey(for: identifier)
        // let _  = try await aws.deleteObject(bucket: bucket, key: key)
        let _  = try await aws.s3.deleteObject(.init(bucket: bucket, key: key))
    }
}