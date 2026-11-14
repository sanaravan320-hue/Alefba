import SwiftUI
import PencilKit

/// Tracing a whole favourite word over its joined shape.
struct WordTraceView: View {
    let word: FavoriteWord
    @Binding var path: NavigationPath
    @Environment(ProgressStore.self) private var progress

    private let guide: LetterGuide
    private let masks: GuideMasks

    @State private var mode: TraceMode = .free
    @State private var drawing = PKDrawing()
    @State private var resetToken = 0
    @State private var pencilOnly = false
    @State private var currentFit = GuideFit(size: .zero)
    @State private var strokeCount = 0
    @State private var liveScore: Double = 0
    @State private var result: TraceResult?

    init(word: FavoriteWord, path: Binding<NavigationPath>) {
        self.word = word
        self._path = path
        let guide = LetterGuide.make(forWord: word)
        self.guide = guide
        self.masks = GuideMasks.cached(for: "word:" + word.id, guide: guide)
    }

    private var nextWord: FavoriteWord? {
        let list = Words.words(in: word.category)
        guard let i = list.firstIndex(of: word), i + 1 < list.count else { return nil }
        return list[i + 1]
    }

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 18) {
                ZStack {
                    HStack {
                        BackButton(title: word.latin) { path.removeLast() }
                        Spacer()
                        SpeakerButton(key: word.voiceKey, text: word.text, label: "Hear \(word.latin)", size: 40)
                    }
                    ModePicker(mode: $mode, modes: [.free, .scored])
                }
                .frame(height: 56)

                HStack(alignment: .top, spacing: 24) {
                    sidePanel.frame(width: 300)
                    canvasCard
                }
            }
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: mode) { _, _ in refreshLive(drawing) }
        .fullScreenCover(item: $result) { r in
            ScoreView(result: r,
                      guide: guide,
                      streak: progress.streak,
                      todayCount: progress.todayCount,
                      backTitle: word.latin,
                      nextDisplay: nextWord?.text,
                      nextLabel: "Next word",
                      onRetry: {
                          result = nil
                          clear()
                      },
                      onNext: {
                          result = nil
                          if let next = nextWord {
                              path.removeLast()
                              path.append(Route.traceWord(next.id))
                          }
                      },
                      onBack: {
                          result = nil
                          path.removeLast()
                      })
        }
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(word.text)
                .font(AppFont.farsi(56))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .inkBox(Ink.saffron, radius: 18)
            Text(word.latin).font(AppFont.display(28))
            Text(word.meaning).font(AppFont.body(17)).foregroundStyle(Ink.muted)

            VStack(alignment: .leading, spacing: 6) {
                Text("HOW TO WRITE IT")
                    .font(AppFont.body(13, .bold))
                    .tracking(1)
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    StepRow(number: index + 1, text: step,
                            active: index == min(strokeCount > 0 ? 1 : 0, guide.steps.count - 1),
                            done: false)
                }
            }

            Text("Letters with an × don’t join the next one, so leave a small gap after them.")
                .font(AppFont.body(14))
                .foregroundStyle(Ink.muted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .inkBox(Ink.card, radius: 24)
    }

    private var canvasCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                if mode == .scored {
                    Text("On the path").font(AppFont.body(16, .semibold))
                    ProgressBar(value: liveScore).frame(maxWidth: 240)
                    Text("\(Int((liveScore * 100).rounded()))%")
                        .font(AppFont.display(24))
                        .monospacedDigit()
                    Spacer()
                    StarRow(filled: TraceScorer.stars(for: liveScore), size: 24)
                } else {
                    Text("Trace the grey word. Start on the right, write each joined part, then add the dots.")
                        .font(AppFont.body(16))
                    Spacer()
                }
            }
            .padding(.horizontal, 18)
            .frame(minHeight: 68)

            DashedRule()

            GeometryReader { geo in
                let fit = GuideFit(size: geo.size)
                ZStack {
                    GuideLayer(guide: guide, fit: fit, showCenterline: false)
                        .allowsHitTesting(false)
                    PencilCanvas(drawing: $drawing,
                                 resetToken: resetToken,
                                 pencilOnly: pencilOnly,
                                 inkWidth: max(9, masks.inkWidth * fit.scale)) { newDrawing in
                        currentFit = fit
                        refreshLive(newDrawing, fit: fit)
                    }
                }
                .onAppear { currentFit = fit }
                .onChange(of: geo.size) { _, newSize in currentFit = GuideFit(size: newSize) }
            }
            .padding(8)

            DashedRule()

            HStack(spacing: 10) {
                Button(action: undo) { Label("Undo", systemImage: "arrow.uturn.backward") }
                    .buttonStyle(PillButtonStyle())
                    .disabled(drawing.strokes.isEmpty)
                Button(action: clear) { Label("Clear", systemImage: "eraser") }
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
                    Label("Done", systemImage: "checkmark").labelStyle(TrailingIconLabelStyle())
                }
                .buttonStyle(PillButtonStyle(kind: .primary))
                .disabled(drawing.strokes.isEmpty)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Ink.sheet))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Ink.ink, lineWidth: 2))
    }

    // MARK: Actions

    private func strokesInGuideSpace(_ d: PKDrawing, fit: GuideFit) -> [[CGPoint]] {
        let zoom = PencilCanvas.zoom(for: max(9, masks.inkWidth * fit.scale))
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
        let r = TraceScorer.evaluate(word: word, guide: guide, masks: masks, strokes: strokes)
        progress.record(word, stars: r.stars)
        result = r
    }
}
