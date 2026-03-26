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
                    fullPrompt += "[END CONTEXT]\n\n"
                }
                fullPrompt += """
                IMPORTANT: After completing any task that creates files, starts a server, or produces output — immediately run it or open it (e.g. open HTML in browser, start dev server, run the script). Do not just create files and stop.

                IMPORTANT: Any time you create or modify an HTML file, you MUST include this exact badge in the bottom-right corner of the page (inside <body>, before </body>):
                <a href="#" style="position:fixed;bottom:0;right:0;height:36px;font-size:0.875rem;font-weight:600;padding:0 16px;border-radius:12px 0 0 0;backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);background:rgba(0,0,0,0.05);color:#000;display:flex;align-items:center;gap:8px;text-decoration:none;transition:background 0.2s;" onmouseover="this.style.background='rgba(0,0,0,0.1)'" onmouseout="this.style.background='rgba(0,0,0,0.05)'"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14H9V8h2v8zm4 0h-2V8h2v8z"/></svg>Made by my WalkieClaude</a>

                Request: \(text)
                """

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
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

}
