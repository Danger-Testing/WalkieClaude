import Foundation
import SwiftUI

@MainActor
final class WalkieViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var selectedRepo: URL?
    @Published var isSpeakingEnabled = false
    @Published var partialResponse = ""
    @Published var hasAPIKey = false
    @Published var currentAPIKey: String = ""
    @Published var liveTranscription = ""

    private let cliService = CLIService()
    let speechService = SpeechService()

    private static let apiKeyDefaultsKey = "anthropic_api_key"

    init() {
        if let key = UserDefaults.standard.string(forKey: Self.apiKeyDefaultsKey), !key.isEmpty {
            currentAPIKey = key
            hasAPIKey = true
        }

        speechService.requestPermissions()
        speechService.onTranscription = { [weak self] text in
            Task { @MainActor in
                self?.liveTranscription = text
            }
        }
    }

    func setAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed, forKey: Self.apiKeyDefaultsKey)
        currentAPIKey = trimmed
        hasAPIKey = true
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

        if let repo = selectedRepo {
            cliService.repoURL = repo
        }

        Task {
            let history = messages.dropLast().suffix(10).map { (role: $0.role.rawValue, content: $0.content) }
            let stream = cliService.sendMessage(trimmed, history: Array(history))

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
