import Foundation
import JWTKit

struct DCPayload: JWTPayload {
    /// JWT Issueer which should be the keyID
    let iss: String
    /// When issued time stamp
    let iat: Int = Date().timeIntervalSince1970.seconds
    /// Subject - bundle id of app that requested the data
    let sub: String
    /// When expiration happens
    let exp: Int
    
    ///
    /// - Parameters:
    ///   - iss: Issuer this should be the teamID
    ///   - sub: Bundle ID of the app
    ///   - exp: How long after the issued time stamp should this token expire
    init(iss: String, sub: String, exp: Int) {
        self.iss = iss
        self.exp = exp + iat
        self.sub = sub
    }
    
    enum CodingKeys: CodingKey {
        case iss
        case sub
        case exp
        case iat
    }

    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        // Don't need to verify anything, but this funciton is Needed to conform
        // to the protocol
    }
}
