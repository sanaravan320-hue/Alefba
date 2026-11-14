import SwiftUI

struct ScoreView: View {
    let result: TraceResult
    let guide: LetterGuide
    let streak: Int
    let todayCount: Int
    let backTitle: String
    /// Farsi text of what comes next (a letter or a word), or nil at the end.
    let nextDisplay: String?
    var nextLabel: String = "Next letter"
    var onRetry: () -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var replay: CGFloat = 1
    @State private var replayToken = 0

    var body: some View {
        ZStack {
            PaperBackground()
            Confetti()
                .frame(width: 420, height: 200)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 60)
                .padding(.trailing, 30)
                .opacity(result.stars >= 2 ? 1 : 0)

            VStack(spacing: 20) {
                HStack {
                    BackButton(title: backTitle, action: onBack)
                    Spacer()
                }
                .frame(height: 56)

                HStack(alignment: .top, spacing: 32) {
                    resultCard
                    summary
                        .frame(maxWidth: 470)
                }
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 48)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .task(id: replayToken) {
            guard replayToken > 0 else { return }
            replay = 0
            for step in 1...60 {
                try? await Task.sleep(nanoseconds: 25_000_000)
                replay = CGFloat(step) / 60
            }
        }
    }

    // MARK: Left: his letter over the guide

    private var resultCard: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Your").font(AppFont.display(26))
                    Text(result.display).font(AppFont.letter(32)).lineLimit(1).minimumScaleFactor(0.5)
                }
                Spacer()
                HStack(spacing: 14) {
                    legend(color: Ink.ink.opacity(0.14), height: 10, text: "guide")
                    legend(color: Ink.ink, height: 6, text: "your ink")
                }
            }

            DashedRule()
            Canvas { context, size in
                let fit = GuideFit(size: size)
                let inkWidth = result.inkWidth
                context.fill(Path(guide.outline).applying(fit.transform), with: .color(Ink.ink.opacity(0.1)))
                let total = result.strokes.reduce(0) { $0 + $1.count }
                var budget = Int(CGFloat(total) * replay)
                for stroke in result.strokes {
                    guard budget > 0 else { break }
                    let points = Array(stroke.prefix(budget))
                    budget -= points.count
                    guard let first = points.first else { continue }
                    var line = Path()
                    line.move(to: fit.toView(first))
                    for p in points.dropFirst() { line.addLine(to: fit.toView(p)) }
                    if points.count == 1 {
                        let r = inkWidth / 2 * fit.scale
                        let c = fit.toView(first)
                        context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Ink.ink))
                    } else {
                        context.stroke(line, with: .color(Ink.ink),
                                       style: StrokeStyle(lineWidth: inkWidth * fit.scale, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            .accessibilityLabel("Your \(result.title) drawn over the guide")
            DashedRule()

            HStack(spacing: 12) {
                if result.checkpointsTotal > 0 {
                    StatTile(value: "\(result.checkpointsHit) / \(result.checkpointsTotal)", label: "checkpoints", color: Tint.turquoise.color)
                }
                StatTile(value: "\(percent(result.precision))%", label: "on the path", color: Tint.saffron.color)
                StatTile(value: "\(percent(result.recall))%", label: "of the letter covered", color: Tint.coral.color)
            }

            Button {
                replayToken += 1
            } label: {
                Label("Replay my stroke", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Ink.sheet))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Ink.ink, lineWidth: 2))
    }

    private func legend(color: Color, height: CGFloat, text: String) -> some View {
        HStack(spacing: 6) {
            Capsule().fill(color).frame(width: 22, height: height)
            Text(text).font(AppFont.body(14, .semibold)).foregroundStyle(Ink.muted)
        }
    }

    private func percent(_ value: Double) -> Int { Int((value * 100).rounded()) }

    // MARK: Right: result and next steps

    private var summary: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("\(result.title) · traced".uppercased())
                .font(AppFont.body(13, .bold))
                .tracking(1)
            Text(result.headline)
                .font(AppFont.display(60))
            StarRow(filled: result.stars, size: 64)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(result.feedback, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(item.good ? Ink.turquoise : Ink.coral)
                            Circle().strokeBorder(Ink.ink, lineWidth: 2)
                            Image(systemName: item.good ? "checkmark" : "exclamationmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(Ink.ink)
                        }
                        .frame(width: 30, height: 30)
                        .accessibilityHidden(true)
                        Text(item.text)
                            .font(AppFont.body(17))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 14) {
                InkDrop(size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(streak > 0 ? "Streak · \(streak) day\(streak == 1 ? "" : "s")" : "Trace with 1+ star to start a streak")
                        .font(AppFont.body(17, .bold))
                    Text(todayLine)
                        .font(AppFont.body(15))
                        .foregroundStyle(Ink.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .inkBox(Tint.lapis.color, radius: 18)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("Try again").frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())

                if let next = nextDisplay {
                    Button {
                        onNext()
                    } label: {
                        HStack(spacing: 10) {
                            Text(nextLabel)
                            Text(next).font(AppFont.letter(24)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(kind: .primary))
                }
            }
        }
        .padding(.top, 24)
    }

    private var todayLine: String {
        let goal = ProgressStore.dailyGoal
        if todayCount >= goal { return "Today: \(todayCount) letters. Goal reached!" }
        let left = goal - todayCount
        return "Today: \(todayCount) of \(goal) letters. \(left) more to go."
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.display(26)).monospacedDigit()
            Text(label).font(AppFont.body(14, .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .inkBox(color, radius: 16)
    }
}

private struct Confetti: View {
    var body: some View {
        Canvas { context, _ in
            let shapes: [(CGRect, Color)] = [
                (CGRect(x: 33, y: 53, width: 14, height: 14), Ink.saffron),
                (CGRect(x: 261, y: 144, width: 12, height: 12), Ink.coral),
                (CGRect(x: 375, y: 95, width: 10, height: 10), Ink.ink),
                (CGRect(x: 300, y: 28, width: 16, height: 16), Tint.lapis.color)
            ]
            for (rect, color) in shapes {
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.stroke(Path(ellipseIn: rect), with: .color(Ink.ink), lineWidth: 2)
            }
            var tri = Path()
            tri.move(to: CGPoint(x: 120, y: 20))
            tri.addLine(to: CGPoint(x: 134, y: 44))
            tri.addLine(to: CGPoint(x: 106, y: 44))
            tri.closeSubpath()
            context.fill(tri, with: .color(Tint.turquoise.color))
            context.stroke(tri, with: .color(Ink.ink), lineWidth: 2)
            var wave = Path()
            wave.move(to: CGPoint(x: 210, y: 70))
            wave.addQuadCurve(to: CGPoint(x: 230, y: 70), control: CGPoint(x: 220, y: 54))
            wave.addQuadCurve(to: CGPoint(x: 250, y: 70), control: CGPoint(x: 240, y: 86))
            context.stroke(wave, with: .color(Ink.coralDeep), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
