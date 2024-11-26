import Foundation
import Logging

public enum ApplicationError: Error {
    case envVarNotFound(String)
    case noDataInAuthKey
    
    private var logMessage: String {
        var messagePieces = ["🚨:"]
        switch self {
        case let .envVarNotFound(key):
            messagePieces.append("Not able to get environment variable for key \(key)")
        case .noDataInAuthKey:
            messagePieces.append("No data. Add the environment variable `AUTH_KEY` with a Base64 Encoded string of the AuthKey.p8 file.")
        }

        return messagePieces.joined(separator: " ")
    }
    
    public func logError() {
        Logger(label: "Hippo").error("\(logMessage)")
    }
}
