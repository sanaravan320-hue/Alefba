import SwiftUI

struct HomeView: View {
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 6)

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    HStack(alignment: .top, spacing: 22) {
                        continueCard
                        todayCard
                            .frame(width: 380)
                    }
                    .frame(height: 214)

                    WordsSection(path: $path)

                    HStack(alignment: .firstTextBaseline) {
                        Text("Letter families")
                            .font(AppFont.display(26))
                        Spacer()
                        (Text("17 shapes · 32 letters · the ")
                            + Text("blue letters").foregroundColor(Ink.lapis).font(AppFont.body(15, .bold))
                            + Text(" show how each one sounds"))
                            .font(AppFont.body(15))
                            .foregroundStyle(Ink.muted)
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Alphabet.families) { family in
                            FamilyTile(family: family,
                                       traced: progress.tracedCount(in: family),
                                       stars: progress.stars(in: family),
                                       isCurrent: family.id == progress.currentFamily.id && !progress.allTraced) {
                                path.append(Route.family(family.id))
                            }
                        }
                        LonersTile {
                            path.append(Route.loners)
                        }
                    }
                }
                .foregroundStyle(Ink.ink)
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text("Alefba")
                    .font(AppFont.display(44))
                Text("الفبا")
                    .font(AppFont.farsi(28))
                    .foregroundStyle(Ink.lapis)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            Chip(text: progress.streak > 0 ? "\(progress.streak)-day streak" : "Start a streak") {
                InkDrop()
            }
            Chip(text: "\(progress.totalStars) stars") {
                SingleStar()
            }
            Button {
                path.append(Route.voices)
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Ink.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Ink.card))
                    .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Record the voices")
        }
        .frame(height: 48)
    }

    // MARK: Continue

    private var continueCard: some View {
        let family = progress.currentFamily
        let next = progress.nextLetter
        return HStack(spacing: 26) {
            VStack(alignment: .leading, spacing: 8) {
                Text(progress.allTraced ? "YOU’VE TRACED THEM ALL" : "PICK UP WHERE YOU LEFT OFF")
                    .font(AppFont.body(13, .bold))
                    .tracking(1)
                Text("\(family.name) family")
                    .font(AppFont.display(36))
                Text(family.blurb)
                    .font(AppFont.body(16))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack(spacing: 16) {
                    Button {
                        path.append(Route.family(family.id))
                    } label: {
                        Label("Continue", systemImage: "arrow.right")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                    .buttonStyle(PillButtonStyle(kind: .primary))
                    Text("\(progress.tracedCount(in: family)) of \(family.letters.count) letters traced")
                        .font(AppFont.body(15, .semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LetterSoundRow(letters: family.letters,
                           letterSize: family.letters.count > 3 ? 56 : 64,
                           soundSize: 18,
                           spacing: 12,
                           minPairWidth: 34,
                           isDimmed: { !progress.isTraced($0) && $0 != next })
                .frame(width: 250)
                .frame(maxHeight: .infinity)
                .inkBox(Ink.card, radius: 18)
        }
        .padding(EdgeInsets(top: 24, leading: 30, bottom: 24, trailing: 24))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkBox(Ink.saffron, radius: 24, shadow: 6)
    }

    // MARK: Today

    private var todayCard: some View {
        let goal = ProgressStore.dailyGoal
        let today = progress.todayCount
        let left = max(0, goal - today)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today").font(AppFont.display(26))
                Spacer()
                Text("\(min(today, goal)) of \(goal) letters")
                    .font(AppFont.body(15, .semibold))
                    .foregroundStyle(Ink.muted)
            }
            ProgressBar(value: Double(today) / Double(goal))
            Text(left == 0 ? "Goal reached. Your streak is safe today!" : "Trace \(left) more letter\(left == 1 ? "" : "s") to keep your streak.")
                .font(AppFont.body(15))
                .foregroundStyle(Ink.muted)
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(progress.currentWeek, id: \.self) { day in
                    DayDot(day: day, done: progress.practiced(on: day), isToday: Calendar.current.isDateInToday(day))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .frame(maxHeight: .infinity)
        .inkBox(Ink.card, radius: 24)
    }
}

private struct DayDot: View {
    let day: Date
    let done: Bool
    let isToday: Bool

    var body: some View {
        Text(day.formatted(.dateTime.weekday(.narrow)))
            .font(AppFont.body(14, .bold))
            .foregroundStyle(done ? Ink.card : Ink.ink)
            .frame(width: 34, height: 34)
            .background(Circle().fill(done ? Ink.lapis : (isToday ? Ink.saffron : Ink.card)))
            .overlay(Circle().strokeBorder(Ink.ink, style: StrokeStyle(lineWidth: 2, dash: isToday && !done ? [4, 3] : [])))
            .accessibilityLabel(day.formatted(.dateTime.weekday(.wide)) + (done ? ", practised" : ""))
    }
}

struct FamilyTile: View {
    let family: LetterFamily
    let traced: Int
    let stars: Int
    let isCurrent: Bool
    let action: () -> Void

    private var complete: Bool { traced == family.letters.count }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    LetterSoundRow(letters: family.letters, letterSize: 28, soundSize: 13, spacing: 8)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text(family.name)
                        .font(AppFont.body(15, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    if isCurrent {
                        Pill(text: "\(traced) / \(family.letters.count)")
                    } else {
                        StarRow(filled: complete ? stars / family.letters.count : 0, size: 15)
                    }
                }
            }
            .foregroundStyle(Ink.ink)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .inkBox(isCurrent ? Ink.saffron : family.tint.color, radius: 18, shadow: isCurrent ? 5 : 0)
        }
        .buttonStyle(.plain)
    }
}

struct LonersTile: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    LetterSoundRow(letters: Alphabet.loners, letterSize: 20, soundSize: 13, spacing: 3, minPairWidth: 15)
                }
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    Text("The 7 loners")
                        .font(AppFont.body(15, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 4)
                    Pill(text: "Lesson", dark: false)
                }
            }
            .foregroundStyle(Ink.ink)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .inkBox(Ink.card, radius: 18, dashed: true)
        }
        .buttonStyle(.plain)
    }
}
