import AppKit

struct SoundEffects {
    static func playChirp() {
        NSSound(named: "Pop")?.play()
    }

    static func playEnd() {
        NSSound(named: "Blow")?.play()
    }
}
