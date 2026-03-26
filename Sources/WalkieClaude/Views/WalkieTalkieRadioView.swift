import SwiftUI
import AppKit

struct WalkieTalkieRadioView: View {
    @StateObject private var viewModel = WalkieViewModel()
    @State private var isTransmitting = false
    @State private var channelNumber: Int = 1
    @State private var gradientAngle: Double = 0
    @State private var timer: Timer? = nil

    private let displayW: CGFloat = 250
    private let displayH: CGFloat = 735
    private let lcdX: CGFloat    = 38
    private let lcdY: CGFloat    = 382
    private let lcdW: CGFloat    = 175
    private let lcdH: CGFloat    = 118

    var body: some View {
        ZStack(alignment: .topLeading) {
            walkieImage
                .resizable()
                .frame(width: displayW, height: displayH)
                .animation(nil, value: gradientAngle)   // never animate the SVG
                .animation(nil, value: channelNumber)

            lcdScreen
                .frame(width: lcdW, height: lcdH)
                .offset(x: lcdX, y: lcdY)
                .allowsHitTesting(false)
        }
        .frame(width: displayW, height: displayH)
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
                startScanAnimation()
            } else {
                stopScanAnimation()
            }
        }
    }

    // MARK: - Scan animation (processing state)

    private func startScanAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            // No withAnimation here — animations are scoped locally on the LCD only
            channelNumber = Int.random(in: 10...99)
            gradientAngle += 45
        }
    }

    private func stopScanAnimation() {
        timer?.invalidate()
        timer = nil
        channelNumber = 1
        gradientAngle = 0
    }

    // MARK: - Image

    private var walkieImage: Image {
        if let url = Bundle.module.url(forResource: "walkie-talkie", withExtension: "svg"),
           let img = NSImage(contentsOf: url) {
            return Image(nsImage: img)
        }
        return Image(systemName: "rectangle.fill")
    }

    // MARK: - LCD

    private var lcdScreen: some View {
        ZStack {
            // Background — static when idle/transmitting, animated gradient when processing
            RoundedRectangle(cornerRadius: 4)
                .fill(lcdFill)
                .animation(.linear(duration: 0.3), value: gradientAngle)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.05))

            VStack(spacing: 0) {
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

                HStack(alignment: .bottom, spacing: 4) {
                    Text("CH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.65))
                        .padding(.bottom, 3)
                    Text(String(format: "%02d", channelNumber))
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.85))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: channelNumber)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
        }
    }

    private var lcdFill: AnyShapeStyle {
        if isTransmitting {
            return AnyShapeStyle(Color(red: 0.95, green: 0.45, blue: 0.05))
        } else if viewModel.isProcessing {
            let angle = gradientAngle * .pi / 180
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.30, green: 0.72, blue: 0.25),
                        Color(red: 0.55, green: 0.82, blue: 0.20),
                        Color(red: 0.25, green: 0.65, blue: 0.40)
                    ],
                    startPoint: .init(x: cos(angle) * 0.5 + 0.5, y: sin(angle) * 0.5 + 0.5),
                    endPoint:   .init(x: cos(angle + .pi) * 0.5 + 0.5, y: sin(angle + .pi) * 0.5 + 0.5)
                )
            )
        } else {
            return AnyShapeStyle(Color(red: 0.53, green: 0.62, blue: 0.20))
        }
    }

    private var signalBars: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(i < 3 ? 0.75 : 0.2))
                    .frame(width: 4, height: CGFloat(5 + i * 3))
            }
        }
    }
}
