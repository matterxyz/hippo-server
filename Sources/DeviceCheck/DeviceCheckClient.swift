import Foundation
#if canImport (FoundationNetworking)
import FoundationNetworking
#endif
import Logging
import JWTKit

/// Communicates to the Apple Device Check API
///
/// Currently only checks if the device token given is a proper Apple device or not
public actor DeviceCheckClient: DeviceCheck {
    /// Private key used for signing the tokens. This is from the `AuthKey_XXXXXXXXX.p8` file
    let key: String
    /// Key Identifier generated at https://developer.apple.com/account/resources/authkeys/list
    let keyID: String
    /// Apple Developer team identifier
    let teamID: String
    /// Bundle ID of your application
    let bundleID: String
    /// Amount of time in seconds the HWT should be kept alive. By default this is 500
    let expire: Int

    private var appleDeviceCheckURL: String

    /// Authorization token for Apple.
    ///
    /// Make up of the token
    /// header
    /// ```
    /// {
    ///   "kid": keyID,
    ///   "alg": "ES256",
    ///   "typ": "JWT"
    /// }
    /// ```
    ///
    /// payload
    /// ```
    /// {
    ///   "sub": bundleID,
    ///   "iss": teamID,
    ///   "exp": expiration time in seconds,
    ///   "iat": issued at in seconds
    /// }
    var jwtToken = ""
    /// Holds the keys
    var keyCollection: JWTKeyCollection

    /// Routes for asset creation based on v0 of hippo
    /// - Parameters:
    ///   - key: The private key used for signing the tokens.
    ///   - keyID: The private key's identifier
    ///   - teamID: The private key's team identifier
    ///   - bundleID: Bundle ID of your application
    ///   - expire: The amount of time in seconds the JWT should be kept alive. This is 500 by default. Max is 1200 seconds (20 minutes).
    ///
    /// By default the device check API being called is set based on the scheme being ran.
    public init(key: String, keyID: String, teamID: String, bundleID: String, expire: Int = 500) {
        self.key = key
        self.keyID = keyID
        self.teamID = teamID
        self.keyCollection = JWTKeyCollection()
        self.bundleID = bundleID
        if expire > 1200 {
            self.expire = 1200
        } else {
            self.expire = expire
        }

        #if DEBUG
        appleDeviceCheckURL = "https://api.development.devicecheck.apple.com/v1/"
        #else
        appleDeviceCheckURL = "https://api.devicecheck.apple.com/v1/"
        #endif
    }

    public static let isValid = { @Sendable (deviceToken: String, deviceCheck: DeviceCheck) async throws -> () in
        try await deviceCheck.check(deviceToken: deviceToken)
    }

    /// Communicate to Apple and makes sure the token is valid
    public func check(deviceToken: String) async throws {
        try await signJWTToken()
        try await validateDeviceToken(for: deviceToken)
    }

    /// Set the Apple DeviceCheck API url to production
    ///
    /// You will usually only want to use this when debugging and you want to run the server in a debug scheme.
    /// The init will handle which URL to use if your scheme is set to DEBUG or RELEASE
    public func shouldUseProductionAPI() {
        appleDeviceCheckURL = "https://api.devicecheck.apple.com/v1/"
    }

    /// Uses the private key to create and sign a JWTToken
    func signJWTToken() async throws {
        let privateKey = key
        // Make a private key
        let ecdsaKey = try ES256PrivateKey(pem: privateKey)
        // Add key to keyCollection with the identifier the Key ID
//        await keyCollection.addES256(key: ecdsaKey, kid: JWKIdentifier(string: keyID))
        await keyCollection.add(ecdsa: ecdsaKey, kid: JWKIdentifier(string: keyID))
        let payload = DCPayload(iss: teamID, sub: bundleID, exp: expire)
        // Make a header that specifices the identifier
        var header = JWTHeader()
        header.kid = keyID
        header.alg = "ES256"
        header.typ = "JWT"
        jwtToken = try await keyCollection.sign(payload, kid: JWKIdentifier(string: keyID), header: header)
    }

    /// Checks that the device token is a valid device token.
    ///
    /// No response from Apple means that the device token is valid
    func validateDeviceToken(for deviceToken: String) async throws {
        let dcURL = appleDeviceCheckURL +  DeviceCheckEndpoint.validatedDeviceToken.rawValue
        guard let url = URL(string: dcURL) else {
            DeviceCheckError.invalidURL.logError()
            throw DeviceCheckError.invalidURL
        }

        let headers = ["Authorization" : "Bearer " + jwtToken,
                       "Content-Type": "application/json"]

        // Construct the request to check with apple
        var requestToApple = URLRequest(url: url)
        requestToApple.httpMethod = "POST"
        // Set headers
        for header in headers {
            requestToApple.addValue(
                header.value,
                forHTTPHeaderField: header.key
            )
        }
        // Set body
        let bodyData = try JSONEncoder().encode(DeviceCheckRequest(deviceToken: deviceToken))
        requestToApple.httpBody = bodyData
        // Make request to apple
        let (data, response) = try await URLSession.shared.asyncData(with: requestToApple)
        let dataString = String(data: data, encoding: .utf8) ?? "NO DATA STRING"
        switch response.status {
            case 200:
                Logger.default.info("✅ Device is valid \(dataString)")
            case 400, 401:
                ResponseError.badResponse(dataString).logError()
                throw ResponseError.badResponse(dataString)
            case 404:
                ResponseError.notFound.logError()
                throw ResponseError.notFound
            default:
                Logger.appleRequest.critical("This response isn't handled \(response.status)  \(dataString)")
                Logger.appleRequest.debug("This response isn't handled")
                throw ResponseError.badResponse("Error unknown \(dataString)")
            }

    }
}
