import App
import ArgumentParser
import Hummingbird
import Logging
import Logging

@main
struct HippoServer: AsyncParsableCommand {
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong)
    var port: Int = 8600

    func run() async throws {
        let app = try await makeApplication(
            hostname: hostname,
            port: port
        )
        try await app.runService()
    }
}
