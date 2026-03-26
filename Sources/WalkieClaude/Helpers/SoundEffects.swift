import AVFoundation

struct SoundEffects {
    // Retain all active players — without this they deallocate before finishing
    private static var players: [AVAudioPlayer] = []
    private static var loopingPlayer: AVAudioPlayer?

    static func playBeep() {
        play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/beep-one.mp4")
    }

    static func playTalking() {
        loopingPlayer?.stop()
        loopingPlayer = nil
        if let p = makePlayer(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/talking-walkie.mp4") {
            p.numberOfLoops = -1
            p.play()
            loopingPlayer = p
        }
    }

    static func playSuccess() {
        loopingPlayer?.stop()
        loopingPlayer = nil
        play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/success.mp4")
    }

    private static func play(path: String) {
        guard let p = makePlayer(path: path) else { return }
        players.append(p)
        p.play()
        // Clean up finished players periodically
        players.removeAll { !$0.isPlaying && $0 !== players.last }
    }

    private static func makePlayer(path: String) -> AVAudioPlayer? {
        let url = URL(fileURLWithPath: path)
        guard let p = try? AVAudioPlayer(contentsOf: url) else {
            print("[SoundEffects] Failed to load: \(path)")
            return nil
        }
        p.prepareToPlay()
        return p
    }
}
