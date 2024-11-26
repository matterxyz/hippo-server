import DeviceCheck

struct DeviceCheckClientPass: DeviceCheck {
    static let isValid: @Sendable (String, any DeviceCheck) async throws -> ()  = { @Sendable (deviceToken: String, deviceCheck: DeviceCheck) async throws -> () in
        try await deviceCheck.check(deviceToken: deviceToken)
    }

    func check(deviceToken: String) async throws {
        return
    }
}

struct DeviceCheckClientFailedVerify: DeviceCheck {
    static let isValid = { @Sendable (deviceToken: String, deviceCheck: DeviceCheck) async throws -> () in
        try await deviceCheck.check(deviceToken: deviceToken)
    }

    func check(deviceToken: String) async throws {
        throw ResponseError.invalidResponse
    }
}
