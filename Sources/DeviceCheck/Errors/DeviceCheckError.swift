import Foundation
import Logging

public enum DeviceCheckError: Error {
    case invalidURL
    case deviceTokenNotFound
    case JWTTokenEmpty
    case NotAbleToSignToken
    
    private var logMessage: String {
        var messagePieces = ["🚨:"]
        
        switch self {
        case .invalidURL:
            messagePieces.append("URL could not be made or is invalid")
        case .deviceTokenNotFound:
            messagePieces.append("No device token found")
        case .JWTTokenEmpty:
            messagePieces.append("JWTToken is empty")
        case .NotAbleToSignToken:
            messagePieces.append("Unable to sign JWT Token")
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
