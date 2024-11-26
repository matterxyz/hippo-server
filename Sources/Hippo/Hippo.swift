//
//  Hippo.swift
//
//
//  Created by Jay Wilson on 1/22/24.
//

import Foundation
import Logging

public final class Hippo: Sendable {
    public let assetsHostName: String
    public let assetsBucketName: String
    public let metadataTable: String
    let objectStorage: ObjectStorage

    public init(
        assetsHostName: String,
        assetsBucketName: String,
        metadataTable: String,
        objectStorage: some ObjectStorage
    ) {
        self.assetsHostName = assetsHostName
        self.assetsBucketName = assetsBucketName
        self.metadataTable = metadataTable
        self.objectStorage = objectStorage
    }

    public func deleteAsset(for user: String, with key: String) async throws {
        try await objectStorage.deleteObject(for: "\(user)/\(key)")
    }

    public func createAsset(using key: String) async throws -> Data {
        guard let futureURL = URL(string: "https://\(assetsHostName)/\(key)") else {
            Logger.asset.error("\(HippoError.failedToMakeAssetURLs.logMessage) future URL failed")
            throw HippoError.failedToMakeAssetURLs
        }

        let (url, fields) = try await objectStorage.getPresignedPost(for: key)
        let asset = AssetData(futureURL: futureURL, postURL: url, postFields: fields)

        guard let data = asset.getJSON() else {
            Logger.asset.error("\(HippoError.failedToMakeAssetURLs.logMessage) can't get json")
            throw HippoError.failedToMakeAssetURLs
        }
        return data
    }
}
