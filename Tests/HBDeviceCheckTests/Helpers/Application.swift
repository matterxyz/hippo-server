import Hummingbird
import Logging
import Logging
import DeviceCheck
import HummingbirdDeviceCheck

func testApp(deviceCheck: any DeviceCheck) async throws -> some ApplicationProtocol {
  let router = Router()
  router.add(middleware: LogRequestsMiddleware(.info))
  router.add(middleware: HummingbirdDeviceCheck(using: deviceCheck))

  router.post("/test") { response, context -> Response in
    let response = Response(status: .ok)
    return response
  }

  let app = Application(router: router)

  return app
}