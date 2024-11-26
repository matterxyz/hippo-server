//
//  Application+configure.swift
//
//
//  Created by Nick Sloan on 1/2/24.
//

import Hummingbird
import Hippo
import HippoAWS
import HippoAPIv1
import Logging
import Foundation
import DeviceCheck

public enum HippoServerError: Error {
    case missingDeviceCheck
}

struct SecretsData: Decodable {
    enum CodingKeys: String, CodingKey {
        case authKey = "DEVICE_CHECK_CERTIFICATE_B64"
    }
    let authKey: String
}

public struct HippoApplication {
    var environment: Environment

    public init(environment: Environment) {
        self.environment = environment
    }
    func createDeviceCheck() throws -> DeviceCheck {
        guard let teamID = environment.get("TEAM_ID") else {
            ApplicationError.envVarNotFound("TEAM_ID").logError()
            throw ApplicationError.envVarNotFound("TEAM_ID")
        }

        guard let keyID = environment.get("KEY_ID") else {
            ApplicationError.envVarNotFound("KEY_ID").logError()
            throw ApplicationError.envVarNotFound("KEY_ID")
        }

        guard let bundleID = environment.get("BUNDLE_ID") else {
            ApplicationError.envVarNotFound("BUNDLE_ID").logError()
            throw ApplicationError.envVarNotFound("KEY_ID")
        }

        // TODO: rename this to APP_SECRETS (here an in the cloudformation/codespace)
        // TODO: clean up errors

        guard let appSecretsJson = environment.get("AUTH_KEY") else {
            ApplicationError.envVarNotFound("AUTH_KEY").logError()
            throw ApplicationError.envVarNotFound("AUTH_KEY")
        }

        guard let secretsData = try? JSONDecoder().decode(SecretsData.self, from: Data(appSecretsJson.utf8)) else {
            ApplicationError.noDataInAuthKey.logError()
            throw ApplicationError.noDataInAuthKey
        }

        // TODO: see if we can move this secondary decode into SecretsData
        guard let keyData = Data(base64Encoded: secretsData.authKey) else {
            ApplicationError.noDataInAuthKey.logError()
            throw ApplicationError.noDataInAuthKey
        }

        guard let key = String(data: keyData, encoding: .utf8) else {
            ApplicationError.noDataInAuthKey.logError()
            throw ApplicationError.noDataInAuthKey
        }

        let deviceCheck = DeviceCheckClient(key: key, keyID: keyID, teamID: teamID, bundleID: bundleID)

        return deviceCheck
    }
}

/// Makes the server application for hippo
/// - Parameters:
///   - hostname: Host
///   - port: Port
///   - logLevel: Default log level to output
///   - testDeviceCheckClient: The device check client to use when testing
/// - Returns: ApplicationProtocol to run or test
public func makeApplication(
    hostname: String,
    port: Int,
    logLevel: Logger.Level = .info,
    withAdditionalRoutes: ((Router<BasicRequestContext>, Hippo, DeviceCheck) -> Void)? = nil,
    testDeviceCheckClient: DeviceCheck? = nil
) async throws -> some ApplicationProtocol {
    let serverName = "Hippo"

    // 🗺️ Environment
    let environment = Environment()

    var deviceCheck: DeviceCheck

    if let testDeviceCheckClient {
        deviceCheck = testDeviceCheckClient
    } else {
        deviceCheck = try HippoApplication(environment: environment).createDeviceCheck()
    }

    // MARK: Logger
    let logger = {
        var logger = Logger(label: serverName)
        logger.logLevel = logLevel
        return logger
    }()
    // MARK: Routerr
    let router = Router()
    // we have to explicitly call middleware to setup the router
    router.add(middleware: LogRequestsMiddleware(logLevel))

    router.get("/") { _, _ -> HTTPResponse.Status in
        return .ok
    }

    guard 
        let assetsHostname = environment.get("ASSETS_HOSTNAME")
    else {
        logger.error("Missing required variable ASSETS_HOSTNAME")
        fatalError()
    }

    guard 
        let assetsBucket = environment.get("ASSETS_BUCKET")
    else {
        logger.error("Missing required variable ASSETS_BUCKET")
        fatalError()
    }

    guard 
        let metadataTable = environment.get("METADATA_TABLE")
    else {
        logger.error("Missing required variable METADATA_TABLE")
        fatalError()
    }
    
    let hippo = Hippo(
        assetsHostName: assetsHostname,
        assetsBucketName: assetsBucket,
        metadataTable: metadataTable,
        objectStorage: S3ObjectStorage(bucket: assetsBucket)
    )

    HippoController(
        metadataTable: metadataTable,
        assetsHostname: assetsHostname,
        assetsBucket: assetsBucket
    ).addRoutes(to: router.group("/v1"))

    if let withAdditionalRoutes {
        withAdditionalRoutes(router, hippo, deviceCheck)
    }

    // MARK: Construct app
    let app = Application(
        router: router,
        configuration: .init(address: .hostname(hostname, port: port)),
        logger: logger
    )
    return app
}
