import SwiftUI

struct WalkieTalkieView: View {
    @StateObject private var viewModel = WalkieViewModel()
    @State private var inputText = ""
    @State private var apiKeyInput = ""
    @State private var showingKeyEditor = false

    var body: some View {
        ZStack {
            // Background body
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)))
                .overlay(
                    Canvas { context, size in
                        let spacing: CGFloat = 12
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            for y in stride(from: 0, through: size.height, by: spacing) {
                                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.03)))
                            }
                        }
                    }
                )

            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text("WALKIE·CLAUDE")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                    Spacer()
                    // Edit API key button
                    Button {
                        apiKeyInput = viewModel.currentAPIKey
                        showingKeyEditor = true
                    } label: {
                        Image(systemName: "key.fill")
                            .foregroundColor(viewModel.hasAPIKey ? .gray : .orange)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 6)
                    // Speaker toggle
                    Button {
                        viewModel.isSpeakingEnabled.toggle()
                    } label: {
                        Image(systemName: viewModel.isSpeakingEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(viewModel.isSpeakingEnabled ? .orange : .gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Working directory picker
                Button {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.prompt = "Select Working Directory"
                        if panel.runModal() == .OK, let url = panel.url {
                            viewModel.selectedRepo = url
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(viewModel.selectedRepo?.lastPathComponent ?? "Downloads (default)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(viewModel.selectedRepo == nil ? .gray : .white)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(white: 0.25), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)

                // Transcript area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if !viewModel.partialResponse.isEmpty {
                                Text(viewModel.partialResponse)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.8))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("partial")
                            }

                            if viewModel.isListening && !viewModel.liveTranscription.isEmpty {
                                Text("🎙 \(viewModel.liveTranscription)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.orange.opacity(0.8))
                                    .padding(8)
                                    .id("listening")
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.partialResponse) { _, _ in
                        proxy.scrollTo("partial", anchor: .bottom)
                    }
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(white: 0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)

                // Transmit button
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                viewModel.isListening
                                    ? Color.red
                                    : Color(red: 0.6, green: 0.1, blue: 0.1)
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: viewModel.isListening ? .red.opacity(0.6) : .clear, radius: 12)

                        Circle()
                            .stroke(Color(white: 0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)

                        VStack(spacing: 2) {
                            Image(systemName: viewModel.isListening ? "waveform" : "mic.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text(viewModel.isListening ? "RELEASE" : "TRANSMIT")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .scaleEffect(viewModel.isListening ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isListening)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !viewModel.isListening {
                                    viewModel.startTransmitting()
                                }
                            }
                            .onEnded { _ in
                                if viewModel.isListening {
                                    viewModel.stopTransmitting()
                                }
                            }
                    )

                    if viewModel.isProcessing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                            Text("PROCESSING...")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Text input
                HStack(spacing: 8) {
                    TextField("Type message...", text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(white: 0.25), lineWidth: 1)
                                )
                        )
                        .onSubmit {
                            viewModel.sendText(inputText)
                            inputText = ""
                        }

                    Button {
                        viewModel.sendText(inputText)
                        inputText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(white: 0.2)))
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            // API key panel — shown on first launch OR when editing
            if !viewModel.hasAPIKey || showingKeyEditor {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 0.97)))
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text(showingKeyEditor ? "EDIT API KEY" : "ENTER API KEY")
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(.orange)
                        Spacer()
                        if showingKeyEditor {
                            Button {
                                showingKeyEditor = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("console.anthropic.com → API Keys")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Plain text so you can see exactly what's stored
                    TextField("sk-ant-api03-...", text: $apiKeyInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.1))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        )
                        .onSubmit {
                            viewModel.setAPIKey(apiKeyInput)
                            showingKeyEditor = false
                        }

                    Button {
                        viewModel.setAPIKey(apiKeyInput)
                        showingKeyEditor = false
                    } label: {
                        Text("CONNECT")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(28)
            }
        }
        .frame(width: 320, height: 480)
        .onAppear {
            if !viewModel.hasAPIKey {
                apiKeyInput = ""
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 2) {
                Text(message.role == .user ? "YOU" : "CLAUDE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(message.role == .user ? .orange : .green)

                Text(message.content)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(message.role == .user
                          ? Color(red: 0.2, green: 0.15, blue: 0.05)
                          : Color(red: 0.05, green: 0.15, blue: 0.05))
            )

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}
