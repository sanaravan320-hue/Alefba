import SwiftUI

/// One favourite word: hear it, see its letters and gaps, then trace it.
struct WordView: View {
    let word: FavoriteWord
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(alignment: .leading, spacing: 22) {
                BackButton(title: "\(Words.ownerName)’s words") { path.removeLast() }

                HStack(alignment: .top, spacing: 32) {
                    hero
                    illustration
                }

                breakdown

                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusLine)
                            .font(AppFont.body(17, .semibold))
                        Text("You can trace it any time. Learning its letters first makes it easier.")
                            .font(AppFont.body(15))
                            .foregroundStyle(Ink.muted)
                    }
                    Spacer()
                    Button {
                        path.append(Route.traceWord(word.id))
                    } label: {
                        Label("Trace the word", systemImage: "pencil.tip")
                    }
                    .buttonStyle(PillButtonStyle(kind: .primary))
                }
                .padding(.leading, 24)
                .padding(.trailing, 14)
                .padding(.vertical, 12)
                .inkBox(progress.isReady(word) ? Tint.pistachio.color : Ink.card, radius: 22)
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 48)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var statusLine: String {
        let learned = progress.lettersLearned(in: word)
        let total = word.letters.count
        if learned == total { return "You know every letter in this word. Ready to write!" }
        return "You know \(learned) of its \(total) letters."
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word.category.title.uppercased())
                .font(AppFont.body(13, .bold))
                .tracking(1)
            HStack(alignment: .center, spacing: 16) {
                Text(word.text)
                    .font(AppFont.farsi(96))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                SpeakerButton(key: word.voiceKey, text: word.text, label: "Hear \(word.latin)", size: 48)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(word.latin).font(AppFont.display(32))
                Text(word.meaning).font(AppFont.body(20)).foregroundStyle(Ink.muted)
            }
            if progress.stars(for: word) > 0 {
                StarRow(filled: progress.stars(for: word), size: 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var illustration: some View {
        IllustrationBox(name: word.illustrationName, label: word.meaning, size: 180)
    }

    private var breakdown: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text("ITS LETTERS, RIGHT TO LEFT")
                    .font(AppFont.body(13, .bold))
                    .tracking(1)
                Spacer()
                HStack(spacing: 14) {
                    legendJoin
                    legendGap
                }
            }
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    Spacer(minLength: 0)
                    // reversed so the first letter sits on the right, as in Farsi
                    ForEach(Array(word.pieces.reversed().enumerated()), id: \.offset) { _, piece in
                        pieceView(piece)
                    }
                }
                .frame(minWidth: 1090, alignment: .trailing)
                .padding(.vertical, 6)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.trailing)
        }
        .padding(20)
        .inkBox(Ink.card, radius: 22)
    }

    @ViewBuilder
    private func pieceView(_ piece: WordPiece) -> some View {
        switch piece {
        case .letter(let shown, let letter):
            let known = progress.isTraced(letter)
            Button {
                path.append(Route.traceInWord(letter.char, word.id))
            } label: {
                VStack(spacing: 0) {
                    Text(shown)
                        .font(AppFont.letter(40))
                        .foregroundStyle(known ? Ink.ink : Ink.dim)
                        .frame(height: 64)
                    Text(letter.sound)
                        .font(AppFont.body(14, .bold))
                        .foregroundStyle(known ? Ink.lapis : Ink.dimText)
                }
                .frame(width: 70, height: 100)
                .inkBox(known ? Tint.saffron.color : Ink.paper, radius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(letter.name), \(letter.sound)\(known ? "" : ", not learned yet")")
        case .join:
            Capsule().fill(Ink.ink).frame(width: 18, height: 4)
                .accessibilityHidden(true)
        case .gap:
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(Ink.ink)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Ink.coral))
                .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 2))
                .accessibilityLabel("gap")
        case .space:
            Rectangle().fill(Color.clear).frame(width: 34, height: 2)
                .accessibilityLabel("space")
        }
    }

    private var legendJoin: some View {
        HStack(spacing: 6) {
            Capsule().fill(Ink.ink).frame(width: 18, height: 4)
            Text("joined").font(AppFont.body(14, .semibold)).foregroundStyle(Ink.muted)
        }
    }

    private var legendGap: some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .heavy))
                .frame(width: 18, height: 18)
                .background(Circle().fill(Ink.coral))
                .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 1.5))
            Text("gap after a loner").font(AppFont.body(14, .semibold)).foregroundStyle(Ink.muted)
        }
    }
}
