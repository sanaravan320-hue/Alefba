import SwiftUI

/// "Recording studio": record a voice for every letter and example word.
struct VoiceRecorderView: View {
    @Binding var path: NavigationPath
    @Environment(VoiceStore.self) private var voices
    @State private var micAllowed: Bool?

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(alignment: .leading, spacing: 18) {
                header

                if micAllowed == false {
                    Text("Microphone access is off. Turn it on in Settings › Alefba › Microphone to record.")
                        .font(AppFont.body(16, .semibold))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .inkBox(Tint.coral.color, radius: 16)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(Alphabet.families) { family in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(family.name) family")
                                    .font(AppFont.display(22))
                                ForEach(family.letters) { letter in
                                    VoiceRow(letter: letter, enabled: micAllowed == true)
                                }
                            }
                        }
                        ForEach(Words.categories) { category in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(Words.ownerName)’s words · \(category.title)")
                                    .font(AppFont.display(22))
                                ForEach(Words.words(in: category)) { word in
                                    FavoriteVoiceRow(word: word, enabled: micAllowed == true)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 48)
            .padding(.top, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            micAllowed = await voices.requestMicrophone()
        }
        .onDisappear {
            voices.stopRecording()
            voices.stopPlayback()
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                BackButton(title: "Home") { path.removeLast() }
                Text("Record the voices")
                    .font(AppFont.display(44))
                Text("Tap the mic, say it, tap stop. For letters, say the name then the sound, like “be… b”. Recordings stay on this iPad.")
                    .font(AppFont.body(17))
                    .foregroundStyle(Ink.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            let files = voices.allRecordings
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(files.count) of \(Alphabet.allLetters.count * 2 + Words.all.count) recorded")
                    .font(AppFont.body(16, .semibold))
                if !files.isEmpty {
                    ShareLink(items: files) {
                        Label("Share recordings", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PillButtonStyle())
                }
            }
        }
    }
}

private struct VoiceRow: View {
    let letter: Letter
    let enabled: Bool

    var body: some View {
        HStack(spacing: 18) {
            Text(letter.char)
                .font(AppFont.letter(40))
                .frame(width: 60, height: 60)
                .inkBox(Tint.saffron.color, radius: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(letter.name).font(AppFont.display(22))
                Text("sound “\(letter.sound)”").font(AppFont.body(14)).foregroundStyle(Ink.muted)
            }
            .frame(width: 130, alignment: .leading)

            RecordControls(key: letter.voiceKey, text: letter.char, title: "Letter", enabled: enabled)

            Rectangle().fill(Ink.rule).frame(width: 2, height: 44)

            VStack(alignment: .leading, spacing: 0) {
                Text(letter.word).font(AppFont.farsi(24))
                Text("\(letter.wordLatin) · \(letter.meaning)").font(AppFont.body(14)).foregroundStyle(Ink.muted)
            }
            .frame(width: 150, alignment: .leading)

            RecordControls(key: letter.wordVoiceKey, text: letter.word, title: "Word", enabled: enabled)

            Spacer(minLength: 0)
        }
        .padding(12)
        .inkBox(Ink.card, radius: 18)
    }
}

private struct FavoriteVoiceRow: View {
    let word: FavoriteWord
    let enabled: Bool

    var body: some View {
        HStack(spacing: 18) {
            Text(word.text)
                .font(AppFont.farsi(26))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 200, height: 60)
                .inkBox(Tint.pistachio.color, radius: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(word.latin).font(AppFont.display(22))
                Text(word.meaning).font(AppFont.body(14)).foregroundStyle(Ink.muted)
            }
            .frame(width: 220, alignment: .leading)
            RecordControls(key: word.voiceKey, text: word.text, title: "Word", enabled: enabled)
            Spacer(minLength: 0)
        }
        .padding(12)
        .inkBox(Ink.card, radius: 18)
    }
}

private struct RecordControls: View {
    let key: String
    let text: String
    let title: String
    let enabled: Bool

    @Environment(VoiceStore.self) private var voices

    var body: some View {
        let isRecording = voices.recordingKey == key
        let recorded = voices.hasRecording(key)
        HStack(spacing: 8) {
            Button {
                if isRecording {
                    voices.stopRecording()
                } else {
                    voices.startRecording(key)
                }
            } label: {
                Label(isRecording ? "Stop" : (recorded ? "Redo \(title.lowercased())" : "Record \(title.lowercased())"),
                      systemImage: isRecording ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(PillButtonStyle(kind: isRecording ? .accent : .secondary))
            .disabled(!enabled)

            if recorded && !isRecording {
                SpeakerButton(key: key, text: text, label: "Play \(title.lowercased())", size: 36)
                Button {
                    voices.deleteRecording(key)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Ink.coralText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(title.lowercased()) recording")
            }
        }
    }
}
