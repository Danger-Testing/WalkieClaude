import Foundation
import SwiftUI

enum Mode: String, CaseIterable {
    case chat = "CHAT"
    case code = "CODE"
}

@MainActor
final class WalkieViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var currentMode: Mode = .chat
    @Published var selectedRepo: URL?
    @Published var isSpeakingEnabled = false
    @Published var partialResponse = ""
    @Published var hasAPIKey = false
    @Published var liveTranscription = ""

    private var anthropicService: AnthropicService?
    private let cliService = CLIService()
    let speechService = SpeechService()

    private static let apiKeyName = "anthropic_api_key"
    private static let defaultAPIKey = "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"

    init() {
        let key = KeychainService.load(key: Self.apiKeyName) ?? Self.defaultAPIKey
        anthropicService = AnthropicService(apiKey: key)
        hasAPIKey = true

        speechService.requestPermissions()
        speechService.onTranscription = { [weak self] text in
            Task { @MainActor in
                self?.liveTranscription = text
            }
        }
    }

    func setAPIKey(_ key: String) {
        if KeychainService.save(key: Self.apiKeyName, value: key) {
            anthropicService = AnthropicService(apiKey: key)
            hasAPIKey = true
        }
    }

    func startTransmitting() {
        isListening = true
        liveTranscription = ""
        SoundEffects.playChirp()
        speechService.startListening()
    }

    func stopTransmitting() {
        isListening = false
        speechService.stopListening()
        SoundEffects.playEnd()

        let text = liveTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
        liveTranscription = ""
        if !text.isEmpty {
            sendText(text)
        }
    }

    func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = Message(role: .user, content: trimmed)
        messages.append(userMessage)
        isProcessing = true
        partialResponse = ""

        if currentMode == .code {
            if let repo = selectedRepo {
                cliService.repoURL = repo
            }
        }

        Task {
            let stream: AsyncStream<String>
            if currentMode == .chat {
                guard let service = anthropicService else {
                    let errMsg = Message(role: .assistant, content: "[No API key configured]")
                    messages.append(errMsg)
                    isProcessing = false
                    return
                }
                stream = service.sendMessage(trimmed)
            } else {
                stream = cliService.sendMessage(trimmed)
            }

            for await chunk in stream {
                partialResponse += chunk
            }

            let finalText = partialResponse.isEmpty ? "[No response]" : partialResponse
            let assistantMessage = Message(role: .assistant, content: finalText)
            messages.append(assistantMessage)
            partialResponse = ""
            isProcessing = false

            if isSpeakingEnabled {
                speechService.speak(finalText)
            }
        }
    }
}
