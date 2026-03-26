import Foundation

final class AnthropicService: Sendable {
    private let apiKey: String
    private let model = "claude-sonnet-4-6"
    private let systemPrompt = "You are a concise radio operator AI assistant. Keep responses brief and actionable. Start responses with 'Roger.' or 'Copy that.' for fun. When giving code, be minimal."

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ text: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            let task = Task {
                guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
                    continuation.finish()
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "content-type")
                request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                let body: [String: Any] = [
                    "model": self.model,
                    "max_tokens": 1024,
                    "stream": true,
                    "system": self.systemPrompt,
                    "messages": [
                        ["role": "user", "content": text]
                    ]
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                } catch {
                    continuation.finish()
                    return
                }

                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.yield("[Error: No HTTP response]")
                        continuation.finish()
                        return
                    }

                    if httpResponse.statusCode != 200 {
                        var body = ""
                        for try await line in bytes.lines {
                            body += line
                        }
                        continuation.yield("[Error \(httpResponse.statusCode): \(body)]")
                        continuation.finish()
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled { break }

                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        if jsonString == "[DONE]" { break }

                        guard let jsonData = jsonString.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                              let type = event["type"] as? String else { continue }

                        if type == "content_block_delta",
                           let delta = event["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        continuation.yield("[Error: \(error.localizedDescription)]")
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
