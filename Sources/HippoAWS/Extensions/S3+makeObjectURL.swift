import Foundation
import SotoS3

extension S3 {
    public func makeObjectURL(bucket: String, key: String) throws -> URL {
        guard
            var components = URLComponents(string: "\(config.endpoint)"),
            let endpoint = components.host
        else {
            throw AWSWrapperError.generalError("Invalid endpoint URL")
        }

        components.host = "\(bucket).\(endpoint)"
        components.path = key.starts(with: "/") ? key : "/\(key)"

        guard let url = components.url else {
            throw AWSWrapperError.generalError("Unable to create valid URL for object")
        }

        return url
    }
}
