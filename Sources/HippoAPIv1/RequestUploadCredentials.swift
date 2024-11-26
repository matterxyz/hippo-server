import Foundation

struct RequestUploadCredentials: Codable {
  var clientReferenceOwner: String
  var clientReferenceID: String

  enum CodingKeys: String, CodingKey {
    case clientReferenceOwner = "client_reference_owner"
    case clientReferenceID = "client_reference_id"
  }
}