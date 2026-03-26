import AVFoundation

struct SoundEffects {
    private static let queue = DispatchQueue(label: "com.walkieclaude.sounds")
    private static var players: [AVAudioPlayer] = []
    private static var loopingPlayer: AVAudioPlayer?

    static func playBeep() {
        queue.async { _play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/beep-one.mp4") }
    }

    static func playTalking() {
        queue.async {
            loopingPlayer?.stop()
            loopingPlayer = nil
            if let p = makePlayer(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/talking-walkie.mp4") {
                p.numberOfLoops = -1
                p.play()
                loopingPlayer = p
            }
        }
    }

    static func playSuccess() {
        queue.async {
            loopingPlayer?.stop()
            loopingPlayer = nil
            _play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/success.mp4")
        }
    }

    private static func _play(path: String) {
        guard let p = makePlayer(path: path) else { return }
        players.append(p)
        p.play()
        players.removeAll { !$0.isPlaying }
    }

    private static func makePlayer(path: String) -> AVAudioPlayer? {
        let url = URL(fileURLWithPath: path)
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.prepareToPlay()
        return p
    }
}
