import SwiftUI
import AppKit
import Carbon.HIToolbox

@main
struct WalkieClaudeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel?
    private var hotKeyRef: EventHotKeyRef?
    private var globalPTTMonitor: Any?
    private var isTransmitting = false

    // Shared so WalkieTalkieRadioView can observe it
    @MainActor let viewModel = WalkieViewModel()

    // PTT key: Cmd+Shift+"  (keyCode 39)
    private let pttKeyCode: UInt16 = 39

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        createPanel()
        registerHotKey()
        setupGlobalPTT()
    }

    private func createPanel() {
        let (w, h): (CGFloat, CGFloat) = FeatureFlags.classicUI ? (320, 480) : (250, 735)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: w, height: h),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = false
        panel.level = .normal
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let rootView: AnyView = FeatureFlags.classicUI
            ? AnyView(WalkieTalkieView())
            : AnyView(WalkieTalkieRadioView(viewModel: viewModel))

        let hostingView = NSHostingView(rootView: rootView)
        panel.contentView = hostingView

        panel.center()
        panel.orderFrontRegardless()

        self.panel = panel
    }

    // Global PTT monitor — lives for the entire app lifetime, works even when
    // the panel is hidden or another app has focus.
    private func setupGlobalPTT() {
        let isPTT: (NSEvent) -> Bool = { [weak self] event in
            guard let self else { return false }
            return event.keyCode == self.pttKeyCode &&
                   event.modifierFlags.contains(.command) &&
                   event.modifierFlags.contains(.shift)
        }

        globalPTTMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self, isPTT(event) else { return }
            DispatchQueue.main.async {
                if event.type == .keyDown && !event.isARepeat && !self.isTransmitting {
                    self.isTransmitting = true
                    // Show panel if hidden so the user can see what's happening
                    if let panel = self.panel, !panel.isVisible {
                        panel.orderFrontRegardless()
                    }
                    self.viewModel.startTransmitting()
                } else if event.type == .keyUp && self.isTransmitting {
                    self.isTransmitting = false
                    self.viewModel.stopTransmitting()
                }
            }
        }
    }

    private func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x574B4C43)
        hotKeyID.id = 1

        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_W)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, _, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue().togglePanel()
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    }
}
