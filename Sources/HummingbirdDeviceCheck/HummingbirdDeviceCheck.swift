import Foundation
import Hummingbird
import Logging
import HTTPTypes
// TODO: Figure out sendable warning things
@preconcurrency import DeviceCheck

public struct HummingbirdDeviceCheck<Context: RequestContext>: RouterMiddleware {
    let deviceCheck: DeviceCheck

    /// Device check that works on humming bird routers
    ///
    /// - Parameter deviceCheck: Communicates to the Apple Device Check API
    public init(using deviceCheck: DeviceCheck) {
        self.deviceCheck = deviceCheck
    }

    public func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        guard let token = request.headers[.deviceToken] else {
            HummingbirdDeviceCheckError.noDeviceToken.logError()
            throw HummingbirdDeviceCheckError.noDeviceToken.httpResponseError
        }
        // Make sure the errors thrown from `DeviceCheck` are an HBHTTPError
        // so that there is a proper error given
        do {
            try await deviceCheck.check(deviceToken: token)
            try await DeviceCheckClient.isValid(token, deviceCheck)
        } catch let dcError as DeviceCheckError {
            throw HummingbirdDeviceCheckError.deviceCheckError(dcError)
        } catch {
             Logger.default.error("\(error)")
            throw HTTPError(.badRequest)
        }
        return try await next(request, context)
    }
}