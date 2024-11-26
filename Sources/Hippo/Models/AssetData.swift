import Foundation

public struct AssetData: Codable, Equatable {
    public let futureURL: URL
    public let postURL: URL
    public let postFields: [String: String]

    public init(futureURL: URL, postURL: URL, postFields: [String: String]) {
        self.futureURL = futureURL
        self.postURL = postURL
        self.postFields = postFields
    }

    enum CodingKeys: String, CodingKey {
        case futureURL = "future_url"
        case postURL = "post_url"
        case postFields = "post_fields"
    }

    public func getJSON() -> Data? {
        let jsonData = try? JSONEncoder().encode(self)
        return jsonData
    }
}
