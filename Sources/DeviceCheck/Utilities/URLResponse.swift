import Foundation
#if canImport (FoundationNetworking)
import FoundationNetworking
#endif

extension URLResponse {
    var status: Int {
        guard let httpResponse = self as? HTTPURLResponse else {
            ResponseError.invalidResponse.logError()
            return 0
        }
        let code = httpResponse.statusCode
        return code
    }
}
