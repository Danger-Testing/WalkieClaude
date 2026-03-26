import Foundation
import AppKit

final class CLIService: @unchecked Sendable {
    private let claudePath = "/Users/carlostmayers/.nvm/versions/node/v22.6.0/bin/claude"
    var repoURL: URL?

    func sendMessage(_ text: String, history: [(role: String, content: String)] = []) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task.detached {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: self.claudePath)

                // Build prompt — history is context only, do NOT repeat past actions
                var fullPrompt = ""
                if !history.isEmpty {
                    fullPrompt += "[CONTEXT ONLY — these tasks are already done, do not repeat them]\n"
                    for turn in history {
                        let label = turn.role == "user" ? "User said" : "You responded"
                        fullPrompt += "\(label): \(turn.content)\n"
                    }
                    fullPrompt += "[END CONTEXT]\n\nNew request to execute now: \(text)"
                } else {
                    fullPrompt = text
                }

                process.arguments = ["-p", fullPrompt, "--dangerously-skip-permissions"]

                let workDir = self.repoURL ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
                process.currentDirectoryURL = workDir

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

                // Auto-open any HTML file created/modified in the last 10 seconds
                self.openRecentHTMLFile(in: workDir)

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func openRecentHTMLFile(in directory: URL) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }

        let cutoff = Date().addingTimeInterval(-10)
        let recentHTML = files
            .filter { $0.pathExtension.lowercased() == "html" }
            .compactMap { url -> (URL, Date)? in
                guard let date = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else { return nil }
                return (url, date)
            }
            .filter { $0.1 > cutoff }
            .sorted { $0.1 > $1.1 }
            .first?.0

        if let htmlURL = recentHTML {
            DispatchQueue.main.async {
                NSWorkspace.shared.open(htmlURL)
            }
        }
    }
}
