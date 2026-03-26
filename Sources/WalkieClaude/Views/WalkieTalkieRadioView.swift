import SwiftUI
import AppKit

struct WalkieTalkieRadioView: View {
    @StateObject private var viewModel = WalkieViewModel()
    @State private var isTransmitting = false
    @State private var pulse = false

    // Display size — maintains 333:980 aspect ratio
    private let displayW: CGFloat = 250
    private let displayH: CGFloat = 735

    // LCD screen position within the scaled image
    // Original image: screen roughly at x=50–283, y=510–666 out of 333×980
    private let lcdX: CGFloat  = 38
    private let lcdY: CGFloat  = 382
    private let lcdW: CGFloat  = 175
    private let lcdH: CGFloat  = 118

    private var lcdBackground: Color {
        if isTransmitting {
            return Color(red: 0.95, green: 0.45, blue: 0.05)   // amber — transmitting
        } else if viewModel.isProcessing {
            return pulse
                ? Color(red: 0.25, green: 0.80, blue: 0.35)   // bright green pulse
                : Color(red: 0.40, green: 0.52, blue: 0.16)   // dim green
        } else {
            return Color(red: 0.53, green: 0.62, blue: 0.20)  // idle olive LCD
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Walkie-talkie image — loaded from bundled SVG
            walkieImage
                .resizable()
                .frame(width: displayW, height: displayH)

            // LCD overlay
            lcdScreen
                .frame(width: lcdW, height: lcdH)
                .offset(x: lcdX, y: lcdY)
                .allowsHitTesting(false)
        }
        .frame(width: displayW, height: displayH)
        // Click-and-hold anywhere on the walkie-talkie = PTT
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isTransmitting else { return }
                    isTransmitting = true
                    viewModel.startTransmitting()
                }
                .onEnded { _ in
                    guard isTransmitting else { return }
                    isTransmitting = false
                    viewModel.stopTransmitting()
                }
        )
        .onChange(of: viewModel.isProcessing) { _, processing in
            if processing {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                withAnimation(.default) { pulse = false }
            }
        }
    }

    // MARK: - Walkie-talkie image

    private var walkieImage: Image {
        if let url = Bundle.module.url(forResource: "walkie-talkie", withExtension: "svg"),
           let img = NSImage(contentsOf: url) {
            return Image(nsImage: img)
        }
        // Fallback: plain dark rectangle if image fails to load
        return Image(systemName: "rectangle.fill")
    }

    // MARK: - LCD screen

    private var lcdScreen: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(lcdBackground)
                .animation(.easeInOut(duration: 0.15), value: lcdBackground)

            // Subtle scanline overlay
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.06))

            VStack(spacing: 0) {
                // Top row: signal bars + RX/TX indicators
                HStack(alignment: .top) {
                    signalBars
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("RX")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(0.35))
                        Text("TX")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(isTransmitting ? 0.9 : 0.30))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)

                Spacer()

                // Bottom row: CH + channel number
                HStack(alignment: .bottom, spacing: 4) {
                    Text("CH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.65))
                        .padding(.bottom, 3)

                    Text(isTransmitting ? "••" : viewModel.isProcessing ? "??" : "01")
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.85))
                        .animation(.none, value: isTransmitting)
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
                    .fill(Color.black.opacity(
                        i < (viewModel.isProcessing ? 4 : isTransmitting ? 4 : 3) ? 0.75 : 0.2
                    ))
                    .frame(width: 4, height: CGFloat(5 + i * 3))
            }
        }
    }
}
