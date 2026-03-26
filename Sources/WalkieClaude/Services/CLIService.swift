import Foundation

final class CLIService: @unchecked Sendable {
    private let claudePath = "/Users/carlostmayers/.nvm/versions/node/v22.6.0/bin/claude"
    var repoURL: URL?

    func sendMessage(_ text: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task.detached {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.claudePath)
                process.arguments = ["-p", text, "--dangerously-skip-permissions"]

                if let repoURL = self.repoURL {
                    process.currentDirectoryURL = repoURL
                }

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                } catch {
                    continuation.yield("[Error: Could not launch claude CLI — \(error.localizedDescription)]")
                    continuation.finish()
                    return
                }

                let handle = pipe.fileHandleForReading
                let bufferSize = 256

                while true {
                    if Task.isCancelled {
                        process.terminate()
                        break
                    }

                    let data = handle.readData(ofLength: bufferSize)
                    if data.isEmpty { break }

                    if let chunk = String(data: data, encoding: .utf8) {
                        continuation.yield(chunk)
                    }
                }

                process.waitUntilExit()
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
