import Foundation

struct DeviceCheckRequest: Codable {
    /// Token received from apple device
    let deviceToken: String
    /// unique id of the transaction
    let transactionId: String = UUID().uuidString
    /// When the transaction occured
    let timestamp: Int = Date().timeIntervalSince1970.milliseconds
    
    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case transactionId = "transaction_id"
        case timestamp
    }
}
