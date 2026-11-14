import SwiftUI
import PencilKit

enum TraceMode: String, CaseIterable, Identifiable {
    case guided = "Guided"
    case free = "Free"
    case scored = "Scored"
    var id: String { rawValue }
}

struct TraceView: View {
    let letter: Letter
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress

    private let guide: LetterGuide
    private let masks: GuideMasks
    private let family: LetterFamily

    @State private var mode: TraceMode = .guided
    @State private var drawing = PKDrawing()
    @State private var resetToken = 0
    @State private var pencilOnly = false
    @State private var currentFit = GuideFit(size: .zero)
    @State private var hits: Set<Int> = []
    @State private var strokeCount = 0
    @State private var liveScore: Double = 0
    @State private var showingDemo = false
    @State private var demoProgress: CGFloat = 0
    @State private var demoDots = 0
    @State private var result: TraceResult?

    /// Set when the letter was opened from one of his favourite words:
    /// "Next" then follows that word's letters instead of the alphabet.
    let word: FavoriteWord?

    init(letter: Letter, word: FavoriteWord? = nil, path: Binding<NavigationPath>) {
        self.letter = letter
        self.word = word
        self._path = path
        let guide = LetterGuide.make(for: letter)
        self.guide = guide
        self.masks = GuideMasks.cached(for: letter.char, guide: guide)
        self.family = Alphabet.family(of: letter)
    }

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 18) {
                header
                HStack(alignment: .top, spacing: 24) {
                    sidePanel
                        .frame(width: 330)
                    canvasCard
                }
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if guide.isAuthored {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { playDemo() }
            }
        }
        .onChange(of: mode) { _, _ in
            refreshLive(drawing)
        }
        .fullScreenCover(item: $result) { r in
            ScoreView(result: r,
                      guide: guide,
                      streak: progress.streak,
                      todayCount: progress.todayCount,
                      backTitle: backTitle,
                      nextDisplay: nextStep.display,
                      nextLabel: nextStep.label,
                      onRetry: {
                          result = nil
                          clear()
                      },
                      onNext: {
                          let step = nextStep
                          result = nil
                          switch step {
                          case .letter(let next):
                              path.removeLast()
                              if let word {
                                  path.append(Route.traceInWord(next.char, word.id))
                              } else {
                                  path.append(Route.trace(next.char))
                              }
                          case .writeWord(let word):
                              path.removeLast()
                              path.append(Route.traceWord(word.id))
                          case .none:
                              path.removeLast()
                          }
                      },
                      onBack: {
                          result = nil
                          path.removeLast()
                      })
        }
    }

    // MARK: What comes next

    private enum NextStep {
        case letter(Letter)
        case writeWord(FavoriteWord)
        case none

        var display: String? {
            switch self {
            case .letter(let l): return l.char
            case .writeWord(let w): return w.text
            case .none: return nil
            }
        }

        var label: String {
            switch self {
            case .writeWord: return "Now write"
            default: return "Next letter"
            }
        }
    }

    /// Inside a word: the next letter of that word he hasn't learned yet
    /// (then any earlier one he skipped), and once he knows them all, the word itself.
    /// Otherwise: the next letter of the alphabet.
    private var nextStep: NextStep {
        if let word {
            let letters = word.letters
            let index = letters.firstIndex(of: letter) ?? -1
            let later = letters.suffix(from: index + 1).first { !progress.isTraced($0) }
            let earlier = letters.first { !progress.isTraced($0) && $0 != letter }
            if let next = later ?? earlier { return .letter(next) }
            return .writeWord(word)
        }
        if let next = Alphabet.next(after: letter) { return .letter(next) }
        return .none
    }

    private var backTitle: String { word?.latin ?? family.name }

    private var positionText: String {
        if let word {
            let letters = word.letters
            let i = (letters.firstIndex(of: letter) ?? 0) + 1
            return "Letter \(i) of \(letters.count) in \(word.latin)"
        }
        return "Letter \((family.letters.firstIndex(of: letter) ?? 0) + 1) of \(family.letters.count)"
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            HStack {
                BackButton(title: backTitle) { path.removeLast() }
                Spacer()
                Text(positionText)
                    .font(AppFont.body(16, .semibold))
                    .foregroundStyle(Ink.muted)
            }
            ModePicker(mode: $mode)
        }
        .frame(height: 56)
    }

    // MARK: Side panel

    private var currentStep: Int {
        min(strokeCount, max(0, guide.steps.count - 1))
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(letter.char)
                .font(AppFont.letter(108))
                .frame(maxWidth: .infinity)
                .frame(height: 156)
                .inkBox(Ink.saffron, radius: 18)

            HStack(spacing: 4) {
                Text(letter.name).font(AppFont.display(32))
                SpeakerButton(letter: letter, size: 36)
                Spacer()
                Text("sound “\(letter.sound)”").font(AppFont.body(15, .semibold))
            }

            ItalianHint(text: letter.hint)

            VStack(alignment: .leading, spacing: 6) {
                Text("HOW TO WRITE IT")
                    .font(AppFont.body(13, .bold))
                    .tracking(1)
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    StepRow(number: index + 1,
                            text: step,
                            active: index == currentStep,
                            done: index < strokeCount && index != currentStep)
                }
            }

            FormsRow(letter: letter)

            Spacer(minLength: 0)

            if guide.isAuthored {
                Button {
                    playDemo()
                } label: {
                    Label(showingDemo ? "Hide the demo" : "Watch it again", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(kind: .accent))
            } else {
                Text("Trace over the grey letter. Farsi always starts on the right.")
                    .font(AppFont.body(14))
                    .foregroundStyle(Ink.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .inkBox(Ink.card, radius: 24)
    }

    // MARK: Canvas

    private var canvasCard: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 18)
                .frame(minHeight: 68)
            DashedRule()
            GeometryReader { geo in
                let fit = GuideFit(size: geo.size)
                ZStack {
                    GuideLayer(guide: guide, fit: fit, showCenterline: mode == .guided && guide.isAuthored)
                        .allowsHitTesting(false)
                    PencilCanvas(drawing: $drawing,
                                 resetToken: resetToken,
                                 pencilOnly: pencilOnly,
                                 inkWidth: inkWidth(for: fit)) { newDrawing in
                        currentFit = fit
                        refreshLive(newDrawing, fit: fit)
                    }
                    if mode == .guided && guide.isAuthored {
                        GuidedOverlay(guide: guide, fit: fit, hits: hits)
                            .allowsHitTesting(false)
                    }
                    if showingDemo, let body = guide.body {
                        DemoOverlay(stroke: body,
                                    dots: guide.dots,
                                    fit: fit,
                                    progress: demoProgress,
                                    dotsShown: demoDots)
                            .allowsHitTesting(false)
                    }
                }
                .onAppear { currentFit = fit }
                .onChange(of: geo.size) { _, newSize in currentFit = GuideFit(size: newSize) }
            }
            .padding(8)
            DashedRule()
            toolbarRow
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Ink.sheet))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Ink.ink, lineWidth: 2))
    }

    @ViewBuilder
    private var topBar: some View {
        switch mode {
        case .guided:
            HStack(spacing: 12) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Tint.turquoise.color))
                    .overlay(Circle().strokeBorder(Ink.ink, lineWidth: 2))
                    .accessibilityHidden(true)
                Text(guide.isAuthored
                     ? "Start at 1 and pull the bowl to the left. Then add the dots."
                     : "Start on the right and follow the grey shape.")
                    .font(AppFont.body(16))
                Spacer()
                Pill(text: "Stroke \(min(strokeCount + 1, guide.expectedStrokes)) of \(guide.expectedStrokes)")
            }
        case .free:
            HStack {
                (Text("Free practice. ").font(AppFont.body(16, .bold))
                    + Text("No score and no checkpoints. Just get the feel of the shape.").font(AppFont.body(16)))
                Spacer()
            }
        case .scored:
            HStack(spacing: 14) {
                Text("On the path").font(AppFont.body(16, .semibold))
                ProgressBar(value: liveScore)
                    .frame(maxWidth: 240)
                Text("\(Int((liveScore * 100).rounded()))%")
                    .font(AppFont.display(24))
                    .monospacedDigit()
                Spacer()
                StarRow(filled: TraceScorer.stars(for: liveScore), size: 24)
            }
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: 10) {
            Button(action: undo) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(PillButtonStyle())
            .disabled(drawing.strokes.isEmpty)

            Button(action: clear) {
                Label("Clear", systemImage: "eraser")
            }
            .buttonStyle(PillButtonStyle())
            .disabled(drawing.strokes.isEmpty)

            Toggle(isOn: $pencilOnly) {
                Text("Pencil only").font(AppFont.body(15, .semibold))
            }
            .toggleStyle(.switch)
            .tint(Ink.turquoise)
            .fixedSize()
            .padding(.leading, 8)

            Spacer()

            Button(action: finish) {
                Label("Done", systemImage: "checkmark")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .buttonStyle(PillButtonStyle(kind: .primary))
            .disabled(drawing.strokes.isEmpty)
        }
    }

    // MARK: Actions

    /// On-screen ink width that matches the letter's stroke.
    private func inkWidth(for fit: GuideFit) -> CGFloat {
        max(9, masks.inkWidth * fit.scale)
    }

    private func strokesInGuideSpace(_ d: PKDrawing, fit: GuideFit) -> [[CGPoint]] {
        let zoom = PencilCanvas.zoom(for: inkWidth(for: fit))
        return d.strokes.map { stroke in
            stroke.path.interpolatedPoints(by: .distance(3)).map { point in
                let p = point.location.applying(stroke.transform)
                return fit.toGuide(CGPoint(x: p.x * zoom, y: p.y * zoom))
            }
        }
    }

    private func refreshLive(_ d: PKDrawing, fit: GuideFit? = nil) {
        let strokes = strokesInGuideSpace(d, fit: fit ?? currentFit)
        strokeCount = strokes.count
        if showingDemo && !strokes.isEmpty {
            showingDemo = false
        }
        if guide.isAuthored {
            hits = TraceScorer.checkpointHits(guide.checkpoints, strokes: strokes)
        }
        if mode == .scored {
            liveScore = TraceScorer.measure(strokes, masks: masks).score
        }
    }

    private func undo() {
        guard !drawing.strokes.isEmpty else { return }
        var d = drawing
        d.strokes.removeLast()
        drawing = d
        resetToken += 1
        refreshLive(d)
    }

    private func clear() {
        drawing = PKDrawing()
        resetToken += 1
        refreshLive(drawing)
    }

    private func finish() {
        let strokes = strokesInGuideSpace(drawing, fit: currentFit)
        let r = TraceScorer.evaluate(letter: letter, guide: guide, masks: masks, strokes: strokes)
        progress.record(letter, stars: r.stars)
        result = r
    }

    private func playDemo() {
        if showingDemo {
            showingDemo = false
            return
        }
        demoProgress = 0
        demoDots = 0
        showingDemo = true
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 2.2)) { demoProgress = 1 }
        }
        for i in 0..<guide.dots.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4 + Double(i) * 0.45) {
                guard showingDemo else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { demoDots = i + 1 }
            }
        }
    }
}

// MARK: - Pieces

struct ModePicker: View {
    @Binding var mode: TraceMode
    var modes: [TraceMode] = TraceMode.allCases

    var body: some View {
        HStack(spacing: 4) {
            ForEach(modes) { m in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { mode = m }
                } label: {
                    Text(m.rawValue)
                        .font(AppFont.body(16, .semibold))
                        .foregroundStyle(mode == m ? Ink.card : Ink.ink)
                        .padding(.horizontal, 22)
                        .frame(height: 44)
                        .background(Capsule().fill(mode == m ? Ink.ink : Color.clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == m ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Ink.card))
        .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: 2))
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    let active: Bool
    let done: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(active ? Ink.turquoise : (done ? Ink.ink : Ink.card))
                Circle().strokeBorder(Ink.ink, lineWidth: 2)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Ink.card)
                } else {
                    Text("\(number)")
                        .font(AppFont.body(14, .bold))
                        .foregroundStyle(Ink.ink)
                }
            }
            .frame(width: 28, height: 28)
            Text(text)
                .font(AppFont.body(15, active ? .semibold : .regular))
                .foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .frame(minHeight: 40)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(active ? Tint.turquoise.color : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(active ? Ink.ink : Color.clear, lineWidth: 2))
    }
}

/// Ruled lines, the faint letter shape and (guided) the dotted centre line.
struct GuideLayer: View {
    let guide: LetterGuide
    let fit: GuideFit
    let showCenterline: Bool

    var body: some View {
        Canvas { context, size in
            if guide.isAuthored {
                let top = fit.toView(CGPoint(x: 0, y: 135)).y
                let base = fit.toView(CGPoint(x: 0, y: 298)).y
                var topLine = Path()
                topLine.move(to: CGPoint(x: 0, y: top))
                topLine.addLine(to: CGPoint(x: size.width, y: top))
                context.stroke(topLine, with: .color(Ink.lapis.opacity(0.22)),
                               style: StrokeStyle(lineWidth: 2, dash: [8, 10]))
                var baseLine = Path()
                baseLine.move(to: CGPoint(x: 0, y: base))
                baseLine.addLine(to: CGPoint(x: size.width, y: base))
                context.stroke(baseLine, with: .color(Ink.lapis.opacity(0.3)), lineWidth: 2)
            }
            context.fill(Path(guide.outline).applying(fit.transform), with: .color(Ink.ink.opacity(0.1)))
            if showCenterline, let body = guide.body {
                context.stroke(Path(body).applying(fit.transform),
                               with: .color(Ink.lapis.opacity(0.6)),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 11]))
            }
        }
    }
}

/// Start marker, checkpoints, numbered dot targets and the "pull left" arrow.
struct GuidedOverlay: View {
    let guide: LetterGuide
    let fit: GuideFit
    let hits: Set<Int>

    var body: some View {
        Canvas { context, _ in
            let s = fit.scale

            for (i, c) in guide.checkpoints.enumerated() {
                let p = fit.toView(c)
                let r = 9 * s
                let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(hits.contains(i) ? Ink.turquoise : Ink.sheet))
                context.stroke(Path(ellipseIn: rect), with: .color(Ink.ink), lineWidth: 2.5 * s)
            }

            if let start = guide.start {
                let p = fit.toView(CGPoint(x: start.x + 49, y: start.y - 20))
                let r = 20 * s
                let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Ink.turquoise))
                context.stroke(Path(ellipseIn: rect), with: .color(Ink.ink), lineWidth: 2.5 * s)
                context.draw(Text("1").font(AppFont.body(22 * s, .bold)).foregroundColor(Ink.ink), at: p)
            }

            for (i, d) in guide.dots.enumerated() {
                let p = fit.toView(d)
                let r = 22 * s
                context.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                               with: .color(Ink.coralDeep),
                               style: StrokeStyle(lineWidth: 2.5 * s, dash: [5 * s, 5 * s]))
                let labelGuide = CGPoint(x: d.x + (d.x >= 350 ? 42 : -42), y: d.y - 30)
                let lp = fit.toView(labelGuide)
                let lr = 14 * s
                let lrect = CGRect(x: lp.x - lr, y: lp.y - lr, width: lr * 2, height: lr * 2)
                context.fill(Path(ellipseIn: lrect), with: .color(Ink.card))
                context.stroke(Path(ellipseIn: lrect), with: .color(Ink.ink), lineWidth: 2 * s)
                context.draw(Text("\(i + 2)").font(AppFont.body(16 * s, .bold)).foregroundColor(Ink.ink), at: lp)
            }

            let dotsBelow = guide.dots.contains { $0.y > 300 }
            let arrowY: CGFloat = dotsBelow ? 118 : 342
            var shaft = Path()
            shaft.move(to: fit.toView(CGPoint(x: 470, y: arrowY)))
            shaft.addLine(to: fit.toView(CGPoint(x: 302, y: arrowY)))
            context.stroke(shaft, with: .color(Ink.lapis),
                           style: StrokeStyle(lineWidth: 3 * s, lineCap: .round, dash: [10 * s, 8 * s]))
            var head = Path()
            head.move(to: fit.toView(CGPoint(x: 316, y: arrowY - 12)))
            head.addLine(to: fit.toView(CGPoint(x: 300, y: arrowY)))
            head.addLine(to: fit.toView(CGPoint(x: 316, y: arrowY + 12)))
            context.stroke(head, with: .color(Ink.lapis),
                           style: StrokeStyle(lineWidth: 3 * s, lineCap: .round, lineJoin: .round))
            context.draw(Text("pull left").font(AppFont.body(18 * s, .semibold)).foregroundColor(Ink.lapis),
                         at: fit.toView(CGPoint(x: 386, y: dotsBelow ? arrowY - 24 : arrowY + 32)))
        }
    }
}

struct GuideCurve: Shape {
    let cgPath: CGPath
    let transform: CGAffineTransform

    func path(in rect: CGRect) -> Path {
        Path(cgPath).applying(transform)
    }
}

/// Animated stroke-order demo: the bowl draws itself, then the dots pop in.
struct DemoOverlay: View {
    let stroke: CGPath
    let dots: [CGPoint]
    let fit: GuideFit
    let progress: CGFloat
    let dotsShown: Int

    var body: some View {
        ZStack {
            GuideCurve(cgPath: stroke, transform: fit.transform)
                .trim(from: 0, to: progress)
                .stroke(Ink.coralDeep, style: StrokeStyle(lineWidth: 12 * fit.scale, lineCap: .round, lineJoin: .round))
            ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                Circle()
                    .fill(Ink.coralDeep)
                    .frame(width: 24 * fit.scale, height: 24 * fit.scale)
                    .scaleEffect(index < dotsShown ? 1 : 0.3)
                    .opacity(index < dotsShown ? 1 : 0)
                    .position(fit.toView(dot))
            }
        }
        .accessibilityHidden(true)
    }
}
