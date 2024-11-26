import Hippo
import SotoDynamoDB

public struct DynamoDBMetadataStorage {
    var aws: AWSWrapper
    var table: String

    public init(aws: AWSWrapper = AWSWrapper(), table: String) {
        self.aws = aws
        self.table = table
    }

    public func save(_ input: StoredObject) async throws {
        let _ = try await aws.dynamo.putItem(.init(item: input, tableName: table))
    }

    public func get(ownerID: String, reference: String) async throws -> StoredObject {
        let response = try await aws.dynamo.query(
            .init(
                expressionAttributeValues: [
                    ":primaryKey": .s("CLIENT#\(ownerID)"),
                    ":sortKey": .s("OBJECT#\(reference)")
                ],
                indexName: "GSI1",
                keyConditionExpression: "GSI1_PK = :primaryKey AND GSI1_SK = :sortKey",
                tableName: table
            ),
            type: StoredObject.self
        )

        guard let item = response.items?.first else {
            throw HippoError.noObjectFound
        }

        return item
    }

    public func get(path: String) async throws -> StoredObject {
        let response = try await aws.dynamo.getItem(.init(
            key: [
                "PK": .s("STORED_OBJECT#\(path)"),
                "SK": .s("#STORED_OBJECT"),
            ],
            tableName: table
        ), type: StoredObject.self)

        guard let item = response.item else {
            throw HippoError.noObjectFound
        }

        return item
    }

    public func delete(path: String) async throws {
        _ = try await aws.dynamo.deleteItem(.init(
            key: [
                "PK": .s("STORED_OBJECT#\(path)"),
                "SK": .s("#STORED_OBJECT")
            ],
            tableName: table
        ))
    }
}