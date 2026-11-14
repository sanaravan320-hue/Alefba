import SwiftUI

struct FamilyView: View {
    let family: LetterFamily
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(alignment: .leading, spacing: 22) {
                header
                HStack(alignment: .top, spacing: 18) {
                    ForEach(family.letters) { letter in
                        LetterCard(letter: letter,
                                   family: family,
                                   stars: progress.stars(for: letter),
                                   traced: progress.isTraced(letter),
                                   isNext: letter == progress.nextLetter) {
                            path.append(Route.trace(letter.char))
                        }
                        .frame(maxWidth: 300)
                    }
                    if family.letters.count < 4 {
                        Spacer(minLength: 0)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 48)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                BackButton(title: "All families") { path.removeLast() }
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("\(family.name) family")
                        .font(AppFont.display(44))
                    LetterSoundRow(letters: family.letters, letterSize: 30, soundSize: 13, spacing: 10)
                }
                Text(family.blurb)
                    .font(AppFont.body(17))
                    .foregroundStyle(Ink.muted)
            }
            Spacer()
            HStack(spacing: 12) {
                Chip(text: "\(progress.stars(in: family)) of \(family.letters.count * 3) stars") {
                    SingleStar()
                }
                Text("\(progress.tracedCount(in: family)) of \(family.letters.count) traced")
                    .font(AppFont.body(16, .semibold))
                    .foregroundStyle(Ink.card)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Capsule().fill(Ink.ink))
            }
        }
    }
}

struct LetterCard: View {
    let letter: Letter
    let family: LetterFamily
    let stars: Int
    let traced: Bool
    let isNext: Bool
    let onTrace: () -> Void

    private var blockColor: Color {
        if isNext { return Ink.saffron }
        return traced ? family.tint.color : Ink.paper
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                Text(letter.char)
                    .font(AppFont.letter(100))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Group {
                    if isNext {
                        Pill(text: "Up next")
                    } else {
                        StarRow(filled: stars, size: 18)
                    }
                }
                .padding(10)
            }
            .frame(height: 150)
            .inkBox(blockColor, radius: 16)

            HStack(spacing: 4) {
                Text(letter.name).font(AppFont.display(28))
                SpeakerButton(letter: letter, size: 34)
                Spacer()
                Text("sound “\(letter.sound)”").font(AppFont.body(15, .semibold))
            }

            HStack(spacing: 8) {
                Circle().fill(Ink.coralDeep).frame(width: 8, height: 8)
                Text(letter.dots).font(AppFont.body(15))
            }

            ItalianHint(text: letter.hint)

            FormsRow(letter: letter)

            HStack(spacing: 12) {
                IllustrationBox(name: letter.illustrationName, label: letter.meaning)
                VStack(alignment: .leading, spacing: 0) {
                    Text(letter.word)
                        .font(AppFont.farsi(28))
                    (Text(letter.wordLatin).font(AppFont.body(14, .bold)).foregroundColor(Ink.ink)
                        + Text(" · \(letter.meaning)").font(AppFont.body(14)).foregroundColor(Ink.muted))
                }
                Spacer(minLength: 0)
                SpeakerButton(word: letter, size: 32)
            }

            Spacer(minLength: 0)

            Button(action: onTrace) {
                Text(isNext ? "Trace \(letter.name)" : (traced ? "Trace again" : "Trace"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle(kind: isNext ? .primary : .secondary))
        }
        .foregroundStyle(Ink.ink)
        .padding(14)
        .frame(maxHeight: .infinity, alignment: .top)
        .inkBox(Ink.card, radius: 22, shadow: isNext ? 6 : 0)
    }
}

/// Shows your drawing if an image named e.g. "illustration-boz" is in Assets, otherwise a placeholder.
struct IllustrationBox: View {
    let name: String
    let label: String
    var size: CGFloat = 76

    var body: some View {
        Group {
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Ink.ink, lineWidth: 2))
                    .accessibilityLabel(label)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text(label)
                        .font(AppFont.body(11, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(Ink.muted)
                .padding(4)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Ink.paper))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Ink.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5])))
                .accessibilityHidden(true)
            }
        }
    }
}
