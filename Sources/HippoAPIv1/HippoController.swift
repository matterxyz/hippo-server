import Foundation
import Hummingbird
import DeviceCheck
import HippoAWS
import Logging
import SotoCore

let logger = Logger(label: "HippoInternal.main")


public struct HippoController: Sendable {
    let metadataTable: String
    let assetsHostname: String
    let assetsBucket: String

    public init(
        metadataTable: String,
        assetsHostname: String,
        assetsBucket: String
    ) {
        self.metadataTable = metadataTable
        self.assetsHostname = assetsHostname
        self.assetsBucket = assetsBucket
    }

    public func addRoutes(to group: RouterGroup<some RequestContext>) {
        let objectGroup = group.group("/object")
        objectGroup.get(use: self.getObject)
            .post(use: self.createObject)
            .get("/{path}", use: self.fetchObject)
            .delete("/{path}", use: self.deleteObject)
    }

    @Sendable func getObject(request: Request, context: some RequestContext) async throws -> Response {
        // client reference owner from query. This is the client's CloudKit ID
        guard let ownerSubstring = request.uri.queryParameters.first(where: { $0.key == Parameter.clientReferenceOwner})?.value else {
            throw HTTPError(.badRequest, message: "No owner ID found in request")
        }
        // client reference id. This is the object ID
        guard let referenceIDSubstring = request.uri.queryParameters.first(where: { $0.key == Parameter.clientReferenceID })?.value else {
            throw HTTPError(.badRequest, message: "No reference ID found in request")
        }
        let owner = String(ownerSubstring)
        let referenceID = String(referenceIDSubstring)

        context.logger.info("Found owner: \(owner)")
        context.logger.info("Found referenceID: \(referenceID)")

        let storage = DynamoDBMetadataStorage(table: metadataTable)
        do {
            let item = try await storage.get(ownerID: "", reference: "")
            return Response(status: .seeOther, headers: [
                .location: "https://\(assetsHostname)/v1/\(item.key)",
                .lastModified: "2022-03-12T23:45:12Z",
                .hippoPath: "/v1/\(item.key)"
            ], body: ResponseBody()
            )
        } catch {
            throw HTTPError(.notFound, message: "Object not found")
        }
    }

    @Sendable func createObject(request: Request, context: some RequestContext) async throws -> EditedResponse<ResponseUploadCredentials> {
        let requestCreds = try? await request.decode(as: RequestUploadCredentials.self, context: context)

        guard let requestCreds else {
            logger.error("Failed to get request credentials")
            throw HTTPError(.badRequest, message: "No request credentials included in request")
        }

        // make sure that client reference owner and client reference id are not empty
        if requestCreds.clientReferenceOwner.isEmpty {
            logger.error("Failed to get request credentials")
            throw HTTPError(.badRequest, message: "No client reference owner included in request")
        }
        if requestCreds.clientReferenceID.isEmpty {
            logger.error("Failed to get request credentials")
            throw HTTPError(.badRequest, message: "No client reference id included in request")
        }

        let objectStorage = S3ObjectStorage(aws: .init(), bucket: assetsBucket)
        let metadataStorage = DynamoDBMetadataStorage(table: metadataTable)

        // create stored object
        let storedObject = StoredObject(
            key: UUID().uuidString,
            clientID: requestCreds.clientReferenceOwner,
            clientReference: requestCreds.clientReferenceID,
            secret: generateSecret()
        )

        let putURL: URL
        do {
            putURL = try await objectStorage.getPresignedPut(for: storedObject.key)
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            throw HTTPError(.internalServerError, message: "The server encountered an unexpected error")
        }

        do {
            // save the metadata
            try await metadataStorage.save(storedObject)
        } catch {
            if let error = error as? AWSClientError {
                logger.error("Error: \(error.errorCode) \(error.localizedDescription)")
            } else {
                logger.error("Error: \(error.localizedDescription)")
            }
            throw HTTPError(.internalServerError, message: "The server encountered an unexpected error")
        }

        return EditedResponse(
            status: .ok,
            headers: [.contentType : "application/json"],
            response: ResponseUploadCredentials(
                futureURL: objectStorage.makeObjectURL(for: storedObject.key),
                futurePath: "/v1/\(storedObject.key)",
                putURL: putURL,
                objectSecret: storedObject.secret
            )
        )
    }

    @Sendable func fetchObject(request: Request, context: some RequestContext) async throws -> Response {
        let path = try context.parameters.require("path")
        let metadataStorage = DynamoDBMetadataStorage(table: metadataTable)

        do {
            let item = try await metadataStorage.get(path: path)
            context.logger.info("Path: \(path)")
            let response = Response(
                status: .seeOther,
                headers: [.location: "https://\(assetsHostname)/v1/\(item.key)"],
                body: ResponseBody()
            )
            return response
        } catch {
            throw HTTPError(.notFound)
        }
    }

    @Sendable func deleteObject(request: Request, context: some RequestContext) async throws -> Response {
        let path = try context.parameters.require("path")

        let metadataStorage = DynamoDBMetadataStorage(table: metadataTable)

        guard let item = try? await metadataStorage.get(path: path) else {
            throw HTTPError(.notFound)
        }

        let objectSecret = try await request.decode(as: String.self, context: context)

        guard !objectSecret.isEmpty else {
            context.logger.error("No object secret")
            throw HTTPError(.badRequest, message: "No object secret")
        }

        guard objectSecret == item.secret else {
            context.logger.error("object secret does not match")
            throw HTTPError(.forbidden, message: "object secret does not match")
        }

        let objectStorage = S3ObjectStorage(bucket: "")

        try await objectStorage.deleteObject(for: path)
        try await metadataStorage.delete(path: path)

        return Response(status: .noContent)
    }

    /// Generates an object secret that will be sent to the client and stored as part of the objec's metadata.
    /// - Returns: String that is the object's secret to confirm ownership
    private func generateSecret() -> String {
        // this is the number of bytes used in the number generator.
        // 128 bits is probably secure enough based on some googling, but doubling to 256 is a bit safer
        let byteCount = 32 // 32 bytes = 256 bits
        // Initializes an array of ints the length of the byte count
        var randomBytes = [UInt8](repeating: 0, count: byteCount)
        var numberGenerator = SystemRandomNumberGenerator()

        // Make the array with random bytes instead of 0. We can do this 8 bytes at a time
        for i in stride(from: 0, through: byteCount, by: 8) {
            // Generate a random 64 bit number
            let randomNumber = numberGenerator.next()
            // Iterate through the next 8 bytes
            for j in 0..<8 {
                // Only generate random bits if not passed the byteCount needed
                if i + j < byteCount {
                    // Shift bits by 8 and then get the single byte by getting the lowest 8 bits
                    randomBytes[i + j] = UInt8((randomNumber >> (j * 8)) & 0xFF)
                }
            }
        }
        // Turn bytes into strings
        let secret = randomBytes.map { String(format: "%02hhx", $0) }
        // return a single string
        return secret.joined()
    }
}
