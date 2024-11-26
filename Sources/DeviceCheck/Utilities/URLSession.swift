import Foundation
#if canImport (FoundationNetworking)
import FoundationNetworking
#endif

/// Extension that provides async support for fetching a URL
///
/// This can be removed if/when Linux version of Swift provides support for async URLSession
extension URLSession {
  /// A reimplementation of `URLSession.shared.data(with:)`
  /// - Parameter request: URL Request for the data
  /// - Returns: Data and response
  ///
  /// - Usage: `let (data, response) = try await URLSession.shared.asyncData(with: request)`
  func asyncData(with request: URLRequest) async throws -> (Data, URLResponse) {
    try await withCheckedThrowingContinuation { continuation in
      let task = self.dataTask(with: request) { data, response, error in
      if let error = error {
        continuation.resume(throwing: error)
      }
      guard let response = response as? HTTPURLResponse else {
        continuation.resume(throwing: ResponseError.invalidURLResponse)
        return
      }
      guard let data = data else {
        continuation.resume(throwing: ResponseError.noData)
        return
      }
      continuation.resume(returning: (data, response))
      }
      task.resume()
    }
  }
}