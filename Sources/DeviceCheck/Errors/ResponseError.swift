import Foundation
import Logging

public enum ResponseError: Error {
    case badResponse(String)
    case invalidResponse
    case noData
    case invalidURLResponse
    case notFound

    private var logMessage: String {
        var messagePieces = ["🚨:"]

        switch self {
        case .badResponse(let errorMessage):
            messagePieces.append(errorMessage)
        case .invalidResponse:
            messagePieces.append("No response found")
        case .noData:
            messagePieces.append("No data found")
        case .invalidURLResponse:
            messagePieces.append("invalid URLResponse")
        case .notFound:
            messagePieces.append("URL used to make request not found")
        }

        return messagePieces.joined(separator: " ")
    }

    public func printError() {
        print(self.logMessage)
    }

    public func logError(with additionalMessage: String? = nil) {
        var message = self.logMessage
        if let additionalMessage {
            message += " \(additionalMessage)"
        }
        Logger.default.error("\(message)")
    }
}
