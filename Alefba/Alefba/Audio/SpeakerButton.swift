import SwiftUI

/// Round speaker button. Dimmed when there is nothing to play yet.
struct SpeakerButton: View {
    let key: String
    let text: String
    let label: String
    var size: CGFloat = 36

    @Environment(VoiceStore.self) private var voices

    var body: some View {
        let playing = voices.playingKey == key
        let available = voices.canPlay(key)
        Button {
            voices.play(key, fallback: text)
        } label: {
            Image(systemName: playing ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(Ink.ink)
                .frame(width: size, height: size)
                .background(Circle().fill(playing ? Ink.saffron : Ink.card))
                .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 2))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(available ? 1 : 0.35)
        .disabled(!available)
        .accessibilityLabel(available ? label : "\(label), not recorded yet")
    }
}

extension SpeakerButton {
    init(letter: Letter, size: CGFloat = 36) {
        self.init(key: letter.voiceKey, text: letter.char, label: "Hear \(letter.name)", size: size)
    }

    init(word letter: Letter, size: CGFloat = 32) {
        self.init(key: letter.wordVoiceKey, text: letter.word, label: "Hear \(letter.meaning)", size: size)
    }
}
