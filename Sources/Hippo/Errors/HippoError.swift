import Foundation

public enum HippoError: Error {
    case noObjectFound
    case failedToMakeAssetURLs
    
    var logMessage: String {
        var messagePieces = ["🚨:"]
        
        switch self {
        case .noObjectFound:
            messagePieces.append("No object with key found")
        case .failedToMakeAssetURLs:
            messagePieces.append("Failed to make asset URLs")
        }
        
        return messagePieces.joined(separator: " ")
    }
}
