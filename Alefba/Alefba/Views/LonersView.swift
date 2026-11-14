import SwiftUI

/// Lesson on the 7 letters that never join the letter after them.
struct LonersView: View {
    @Binding var path: NavigationPath

    private let shortHints: [String: String] = [
        "ا": "A long, round “a”.",
        "د": "Like the d in dado.",
        "ذ": "Like English zoo, not pizza.",
        "ر": "Rolled, like in Roma.",
        "ز": "Same as zāl: English zoo.",
        "ژ": "Like the j in French jour.",
        "و": "v as in vino, or u / o."
    ]

    private let tints: [Tint] = [.turquoise, .lapis, .lapis, .pistachio, .pistachio, .pistachio, .turquoise]

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Each one takes a hand from the right")
                        Text("\u{0640}").font(AppFont.letter(20))
                        Text("but never gives one to the left")
                        LetGoMark(size: 22)
                    }
                    .font(AppFont.body(15, .semibold))

                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(Alphabet.loners.enumerated()), id: \.element.id) { index, letter in
                            LonerCard(letter: letter, hint: shortHints[letter.char] ?? letter.hint, tint: tints[index])
                        }
                    }
                }

                HStack(alignment: .top, spacing: 20) {
                    LonerWordCard(title: "Every letter holds hands",
                             word: "سبز", latin: "sabz", meaning: "green",
                             parts: [.letter("س"), .join, .letter("ب"), .join, .letter("ز")],
                             caption: "ز is a loner too, but it comes last, so nobody notices.",
                             fill: Tint.turquoise.color, shadow: 0)
                    LonerWordCard(title: "Two loners, two gaps",
                             word: "دوست", latin: "dust", meaning: "friend",
                             parts: [.letter("د"), .gap, .letter("و"), .gap, .letter("س"), .join, .letter("ت")],
                             caption: "د and و let go, so the word breaks into د · و · ست.",
                             fill: Tint.saffron.color, shadow: 6)
                }

                Spacer(minLength: 0)

                HStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Text("Practise the loners, starting with")
                        Text("د").font(AppFont.letter(28))
                        Text("and leave the gaps where they belong.")
                    }
                    .font(AppFont.body(18))
                    .foregroundStyle(Ink.card)
                    Spacer()
                    Button {
                        path.append(Route.trace("د"))
                    } label: {
                        Label("Start practice", systemImage: "arrow.right")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                    .buttonStyle(PillButtonStyle(kind: .accent))
                }
                .padding(.leading, 26)
                .padding(.trailing, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Ink.ink))
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 48)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                BackButton(title: "All families") { path.removeLast() }
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("The 7 loners").font(AppFont.display(44))
                    LetterSoundRow(letters: Alphabet.loners, letterSize: 28, soundSize: 12, spacing: 8)
                }
                Text("They hold hands with the letter before them, never the one after. So words get little gaps.")
                    .font(AppFont.body(17))
                    .foregroundStyle(Ink.muted)
            }
            Spacer()
            Text("Special lesson")
                .font(AppFont.body(15, .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Ink.card))
                .overlay(Capsule().strokeBorder(Ink.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
        }
    }
}

private struct LetGoMark: View {
    var size: CGFloat
    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: size * 0.42, weight: .heavy))
            .foregroundStyle(Ink.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(Ink.coral))
            .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 2))
            .accessibilityLabel("does not join")
    }
}

private struct LonerCard: View {
    let letter: Letter
    let hint: String
    let tint: Tint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .leading) {
                Text("\u{0640}" + letter.char)
                    .font(AppFont.letter(54))
                    .frame(maxWidth: .infinity)
                LetGoMark(size: 22)
                    .padding(.leading, 8)
            }
            .frame(height: 100)
            .overlay(alignment: .topTrailing) {
                SpeakerButton(letter: letter, size: 28)
            }
            .inkBox(tint.color, radius: 14)

            HStack(alignment: .firstTextBaseline) {
                Text(letter.name).font(AppFont.display(20))
                Spacer(minLength: 4)
                Text(letter.sound).font(AppFont.body(14, .bold))
            }
            .padding(.horizontal, 4)

            Text(hint)
                .font(AppFont.body(13))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .top)
        .inkBox(Ink.card, radius: 20)
    }
}

private enum WordPart: Hashable {
    case letter(String)
    case join
    case gap
}

private struct LonerWordCard: View {
    let title: String
    let word: String
    let latin: String
    let meaning: String
    let parts: [WordPart]
    let caption: String
    let fill: Color
    let shadow: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFont.body(13, .bold))
                .tracking(1)
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(word).font(AppFont.letter(80))
                    (Text(latin).font(AppFont.body(15, .bold)) + Text(" · \(meaning)").font(AppFont.body(15)))
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    // reversed so the first letter sits on the right, as in Farsi
                    ForEach(Array(parts.reversed().enumerated()), id: \.offset) { _, part in
                        switch part {
                        case .letter(let char):
                            Text(char)
                                .font(AppFont.letter(26))
                                .frame(width: 46, height: 46)
                                .inkBox(Ink.card, radius: 12)
                        case .join:
                            Capsule().fill(Ink.ink).frame(width: 16, height: 4)
                                .accessibilityLabel("joins")
                        case .gap:
                            LetGoMark(size: 20)
                        }
                    }
                }
            }
            Text(caption)
                .font(AppFont.body(15))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .inkBox(fill, radius: 22, shadow: shadow)
    }
}
