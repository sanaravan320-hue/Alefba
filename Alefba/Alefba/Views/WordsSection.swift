import SwiftUI

/// "Carlo's words" row on the home screen: category tabs and a sideways strip of word cards.
struct WordsSection: View {
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress
    @State private var category: WordCategory = .people

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Text("\(Words.ownerName)’s words")
                    .font(AppFont.display(26))
                CategoryPicker(selection: $category)
                Spacer()
                Text("Learn the letters, then write the words you love")
                    .font(AppFont.body(15))
                    .foregroundStyle(Ink.muted)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(Words.words(in: category)) { word in
                        WordCard(word: word,
                                 learned: progress.lettersLearned(in: word),
                                 stars: progress.stars(for: word)) {
                            path.append(Route.word(word.id))
                        }
                    }
                }
                .padding(.trailing, 48)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)
            .frame(height: 158)
        }
    }
}

private struct CategoryPicker: View {
    @Binding var selection: WordCategory

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Words.categories) { c in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = c }
                } label: {
                    Text(c.title)
                        .font(AppFont.body(15, .semibold))
                        .foregroundStyle(selection == c ? Ink.card : Ink.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Capsule().fill(selection == c ? Ink.ink : Color.clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityAddTraits(selection == c ? .isSelected : [])
            }
        }
        .padding(.horizontal, 4)
        .background(Capsule().fill(Ink.card).frame(height: 44))
        .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: 2).frame(height: 44))
    }
}

struct WordCard: View {
    let word: FavoriteWord
    let learned: Int
    let stars: Int
    let action: () -> Void

    private var total: Int { word.letters.count }
    private var ready: Bool { learned == total }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    if stars > 0 {
                        StarRow(filled: stars, size: 14)
                    } else if ready {
                        Pill(text: "Ready to write")
                    } else {
                        Pill(text: "\(learned) of \(total) letters", dark: false)
                    }
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
                Text(word.text)
                    .font(AppFont.farsi(30))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(word.latin)
                    .font(AppFont.body(15, .bold))
                    .lineLimit(1)
                Text(word.meaning)
                    .font(AppFont.body(13))
                    .foregroundStyle(Ink.muted)
                    .lineLimit(1)
            }
            .foregroundStyle(Ink.ink)
            .padding(12)
            .frame(width: 196, height: 148)
            .inkBox(ready ? Tint.pistachio.color : Ink.card, radius: 18)
        }
        .buttonStyle(.plain)
    }
}
