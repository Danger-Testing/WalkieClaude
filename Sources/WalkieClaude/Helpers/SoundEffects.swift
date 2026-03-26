import AVFoundation

struct SoundEffects {
    private static var player: AVAudioPlayer?

    static func playBeep() {
        play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/beep-one.mp4")
    }

    static func playTalking() {
        play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/talking-walkie.mp4", loops: true)
    }

    static func playSuccess() {
        stopTalking()
        play(path: "/Users/carlostmayers/Downloads/walkie talkie sounds/success.mp4")
    }

    static func stopTalking() {
        player?.stop()
        player = nil
    }

    private static func play(path: String, loops: Bool = false) {
        let url = URL(fileURLWithPath: path)
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return }
        p.numberOfLoops = loops ? -1 : 0
        p.prepareToPlay()
        p.play()
        if loops { player = p } // retain looping player
    }
}
