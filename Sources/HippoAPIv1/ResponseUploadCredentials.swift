import Foundation
import Hummingbird

struct PostFields: Codable {
  var key: String
  var bucket: String
  var amzAlgorithm: String
  var amzDate: String
  var policy: String
  var amzSignature: String

  enum CodingKeys: String, CodingKey {
    case key = "Key"
    case bucket = "Bucket"
    case amzAlgorithm = "X-Amz-Algorithm"
    case amzDate = "X-Amz-Credential"
    case policy = "Policy"
    case amzSignature = "X-Amz-Signature"
  }
}

struct ResponseUploadCredentials: ResponseCodable {
  var futureURL: URL
  var futurePath: String
  var putURL: URL
  var objectSecret: String

  enum CodingKeys: String, CodingKey {
    case futureURL = "future_url"
    case futurePath = "future_path"
    case putURL = "put_url"
    case objectSecret = "object_secret"
  }
}