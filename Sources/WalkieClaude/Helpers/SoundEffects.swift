import AVFoundation

struct SoundEffects {
    private static let queue = DispatchQueue(label: "com.walkieclaude.sounds")
    private static var players: [AVAudioPlayer] = []

    static func playBeep() {
        queue.async { _play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/beep-one.mp4") }
    }

    static func playTalking() {
        queue.async { _play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/talking-walkie.mp4", loops: true) }
    }

    static func playSuccess() {
        queue.async {
            // Kill everything immediately, then play success
            players.forEach { $0.stop() }
            players.removeAll()
            _play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/success.mp4")
        }
    }

    private static func _play(path: String, loops: Bool = false) {
        guard let p = makePlayer(path: path) else { return }
        p.numberOfLoops = loops ? -1 : 0
        players.append(p)
        p.play()
        players.removeAll { !$0.isPlaying && !loops }
    }

    private static func makePlayer(path: String) -> AVAudioPlayer? {
        let url = URL(fileURLWithPath: path)
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.prepareToPlay()
        return p
    }
}
