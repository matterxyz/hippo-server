import Foundation
import Logging

extension Logger {
    private static let label = "DeviceCheck"
    
    static let `default` = Logger(label: "\(label)")
    static let jwt = Logger(label: "\(label)JWT")
    static let appleRequest = Logger(label: "\(label)AppleRequest")
}

