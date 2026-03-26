import SwiftUI
import AppKit

struct WalkieTalkieRadioView: View {
    @StateObject private var viewModel = WalkieViewModel()
    @State private var isListening = false
    @State private var localMonitor: Any?
    @State private var globalMonitor: Any?
    @State private var pulse = false

    // Walkie-talkie image is 333×980, displayed at 250×735
    private let displayW: CGFloat = 250
    private let displayH: CGFloat = 735

    // LCD screen position within the scaled image (tuned to the image)
    private let lcdX: CGFloat = 38
    private let lcdY: CGFloat = 382
    private let lcdW: CGFloat = 175
    private let lcdH: CGFloat = 118

    var lcdColor: Color {
        if isListening {
            return Color(red: 0.95, green: 0.45, blue: 0.05) // amber/orange — transmitting
        } else if viewModel.isProcessing {
            return pulse
                ? Color(red: 0.2, green: 0.75, blue: 0.3)   // bright green pulse
                : Color(red: 0.45, green: 0.55, blue: 0.18) // dim green
        } else {
            return Color(red: 0.53, green: 0.62, blue: 0.20) // idle olive-green LCD
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Walkie-talkie body
            if let img = NSImage(named: "walkie-talkie") {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: displayW, height: displayH)
            }

            // LCD screen overlay
            lcdScreen
                .frame(width: lcdW, height: lcdH)
                .offset(x: lcdX, y: lcdY)
        }
        .frame(width: displayW, height: displayH)
        .onAppear { setupKeyMonitors() }
        .onDisappear { removeKeyMonitors() }
        .onChange(of: viewModel.isProcessing) { _, processing in
            if processing {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                pulse = false
            }
        }
    }

    // MARK: - LCD Screen

    private var lcdScreen: some View {
        ZStack {
            // LCD background
            RoundedRectangle(cornerRadius: 4)
                .fill(lcdColor)
                .animation(.easeInOut(duration: 0.15), value: lcdColor)

            // LCD scanline texture
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.06))

            VStack(spacing: 0) {
                // Top row: signal bars + status
                HStack(alignment: .top) {
                    signalBars
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("RX")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(isListening ? 0.3 : 0.5))
                        Text("TX")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(isListening ? 0.9 : 0.3))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)

                Spacer()

                // Bottom row: CH + channel number
                HStack(alignment: .bottom, spacing: 4) {
                    Text("CH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.bottom, 2)
                    Text(isListening ? "•• " : viewModel.isProcessing ? "??" : "01")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.85))
                        .animation(.none, value: isListening)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
    }

    private var signalBars: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(i < (viewModel.isProcessing ? 4 : 3) ? 0.75 : 0.2))
                    .frame(width: 4, height: CGFloat(5 + i * 3))
            }
        }
    }

    // MARK: - Option Key Monitoring

    private func setupKeyMonitors() {
        // Local: when our panel is key window
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlagsChanged(event)
            return event
        }
        // Global: works when other apps are frontmost too
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlagsChanged(event)
        }
    }

    private func removeKeyMonitors() {
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let optionDown = event.modifierFlags.contains(.option)
        DispatchQueue.main.async {
            if optionDown && !isListening {
                isListening = true
                viewModel.startTransmitting()
            } else if !optionDown && isListening {
                isListening = false
                viewModel.stopTransmitting()
            }
        }
    }
}
