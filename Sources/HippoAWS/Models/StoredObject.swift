import Foundation

public struct StoredObject: Codable {
    public var key: String
    public var clientID: String
    public var clientReference: String
    public var secret: String

    var PK: String { "STORED_OBJECT#\(key)" }
    var SK: String { "#STORED_OBJECT" }
    var GSI1_PK: String { "CLIENT#\(clientID)" }
    var GSI1_SK: String { "OBJECT#\(clientReference)" }

    public init(key: String, clientID: String, clientReference: String, secret: String) {
        self.key = key
        self.clientID = clientID
        self.clientReference = clientReference
        self.secret = secret
    }

    public init(from decoder: any Decoder) throws {
         let values = try decoder.container(keyedBy: CodingKeys.self)
         self.key = try values.decode(String.self, forKey: .key)
         self.clientID = try values.decode(String.self, forKey: .clientID)
         self.clientReference = try values.decode(String.self, forKey: .clientReference)
         self.secret = try values.decode(String.self, forKey: .secret)
         // Don't want to decode the rest of the values cause they are computed properties
    }


    enum CodingKeys: String,  CodingKey {
        case key, clientID, clientReference, secret

        // computed property fields
        case PK, SK
        case GSI1_PK = "GSI1-PK"
        case GSI1_SK = "GSI1-SK"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // DynamoDB Keys
        try container.encode(self.PK, forKey: .PK)
        try container.encode(self.SK, forKey: .SK)
        try container.encode(self.GSI1_PK, forKey: .GSI1_PK)
        try container.encode(self.GSI1_SK, forKey: .GSI1_SK)

        try container.encode(self.clientID, forKey: .clientID)
        try container.encode(self.clientReference, forKey: .clientReference)
        try container.encode(self.secret, forKey: .secret)
    }
}