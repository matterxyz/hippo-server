import Foundation
import DeviceCheck
import Logging
import Hummingbird

public enum HummingbirdDeviceCheckError: Error {
    case noDeviceToken
    case deviceCheckError(DeviceCheckError)

    private var logMessage: String {
        var messagePieces = ["🚨:"]
        switch self {
        case .noDeviceToken:
            messagePieces.append("No device token in headers")
        case .deviceCheckError(_):
            messagePieces.append("DeviceCheck failed")
        }

        return messagePieces.joined(separator: " ")
    }

    func logError() {
        Logger.default.error("\(logMessage)")
    }

    var httpResponseError: HTTPError {
        switch self {
        case .noDeviceToken:
            HTTPError(.badRequest, message: logMessage)
        case .deviceCheckError(_):
            HTTPError(.forbidden)
        }
    }
}
