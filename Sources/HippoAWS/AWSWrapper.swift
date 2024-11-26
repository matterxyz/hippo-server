import Foundation
import SotoCore
import SotoS3
import SotoDynamoDB
import Crypto
import Logging

enum AWSWrapperError: LocalizedError {
    case badURL
    case generalError(String)

    var localizedDescription: String {
        switch self {
        case .badURL:
            return "Bad URL"
        case let .generalError(description):
            return description
        }
    }
}

public class AWSWrapper {
    let client: AWSClient
    let s3: S3
    let dynamo: DynamoDB

    public init(client: AWSClient = AWSClientFactory()) {
        self.client = client
        self.s3 = S3(client: client)
        self.dynamo = DynamoDB(client: client, region: .useast1)
    }

    deinit {
        try? client.syncShutdown()
    }
}

public func AWSClientFactory() -> AWSClient {
    var logger = Logger(label: "Soto")
    logger.logLevel = .warning
    return AWSClient(
        middleware: AWSLoggingMiddleware(logger: logger, logLevel: .trace),
        logger: logger
    )
}