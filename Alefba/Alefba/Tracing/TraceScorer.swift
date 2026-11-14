import CoreGraphics
import Foundation

/// Low-resolution bitmaps of the guide, used to compare it with his ink.
struct GuideMasks {
    static let scale: CGFloat = 0.5
    static let width = Int(LetterGuide.space.width * scale)
    static let height = Int(LetterGuide.space.height * scale)
    /// How far (in guide units) ink may stray from the shape and still count as "on the path".
    static let tolerance: CGFloat = 14

    let shape: [UInt8]
    let tolerant: [UInt8]
    let shapePixelCount: Int
    /// Typical thickness of the letter's stroke, in guide units.
    /// The pencil ink and the coverage check both use it.
    let strokeWidth: CGFloat

    private static var cache: [String: GuideMasks] = [:]

    static func cached(for char: String, guide: LetterGuide) -> GuideMasks {
        if let masks = cache[char] { return masks }
        let masks = GuideMasks(guide: guide)
        cache[char] = masks
        return masks
    }

    init(guide: LetterGuide) {
        let outline = guide.outline
        shape = GuideMasks.render { ctx in
            ctx.addPath(outline)
            ctx.fillPath()
        }
        tolerant = GuideMasks.render { ctx in
            ctx.addPath(outline)
            ctx.fillPath()
            ctx.addPath(outline)
            ctx.setLineWidth(GuideMasks.tolerance * 2)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        }
        shapePixelCount = shape.reduce(0) { $0 + ($1 > 127 ? 1 : 0) }

        if guide.isAuthored {
            strokeWidth = BowlGuide.strokeWidth
        } else {
            // Thickness ≈ 2 × area ÷ outline length, measured on the bitmap.
            let w = GuideMasks.width, h = GuideMasks.height
            var boundary = 0
            for y in 0..<h {
                for x in 0..<w {
                    let i = y * w + x
                    guard shape[i] > 127 else { continue }
                    if x == 0 || y == 0 || x == w - 1 || y == h - 1
                        || shape[i - 1] <= 127 || shape[i + 1] <= 127
                        || shape[i - w] <= 127 || shape[i + w] <= 127 {
                        boundary += 1
                    }
                }
            }
            let pixels = boundary > 0 ? 2 * CGFloat(shapePixelCount) / CGFloat(boundary) : 20
            strokeWidth = min(60, max(16, pixels / GuideMasks.scale))
        }
    }

    /// Width to draw his ink with, in guide units: a little slimmer than the
    /// letter so a careful trace sits inside the grey shape.
    var inkWidth: CGFloat { strokeWidth * 0.9 }

    /// Renders into an 8-bit grey bitmap whose first row is the top of guide space.
    static func render(_ draw: (CGContext) -> Void) -> [UInt8] {
        var data = [UInt8](repeating: 0, count: width * height)
        data.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(data: buffer.baseAddress,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            ctx.translateBy(x: 0, y: CGFloat(height))
            ctx.scaleBy(x: scale, y: -scale)
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.setStrokeColor(gray: 1, alpha: 1)
            ctx.setLineCap(.round)
            draw(ctx)
        }
        return data
    }

    func index(of p: CGPoint) -> Int? {
        let x = Int(p.x * Self.scale)
        let y = Int(p.y * Self.scale)
        guard x >= 0, y >= 0, x < Self.width, y < Self.height else { return nil }
        return y * Self.width + x
    }
}

struct TraceFeedback: Hashable {
    let good: Bool
    let text: String
}

struct TraceResult: Identifiable {
    let id = UUID()
    /// The letter traced, or nil when it was a favourite word.
    let letter: Letter?
    /// "be", or the word's Latin spelling.
    let title: String
    /// What was traced, in Farsi.
    let display: String
    /// Ink width in guide units, for the replay.
    let inkWidth: CGFloat
    /// Share of his ink that stayed on the shape.
    let precision: Double
    /// Share of the shape his ink covered.
    let recall: Double
    let score: Double
    let stars: Int
    let checkpointsHit: Int
    let checkpointsTotal: Int
    /// His strokes in guide space, for the replay on the score screen.
    let strokes: [[CGPoint]]
    let feedback: [TraceFeedback]

    var headline: String {
        switch stars {
        case 3: return "Beautiful!"
        case 2: return "Lovely work!"
        case 1: return "Good start!"
        default: return "Let’s try again"
        }
    }
}

enum TraceScorer {
    static func measure(_ strokes: [[CGPoint]], masks: GuideMasks) -> (precision: Double, recall: Double, score: Double) {
        let points = strokes.flatMap { $0 }
        guard !points.isEmpty else { return (0, 0, 0) }
        // His ink is as thick as the letter, plus a little slack for a wobbly hand.
        let coverWidth = masks.strokeWidth + 8

        var inside = 0
        for p in points {
            if let i = masks.index(of: p), masks.tolerant[i] > 127 { inside += 1 }
        }
        let precision = Double(inside) / Double(points.count)

        let ink = GuideMasks.render { ctx in
            ctx.setLineWidth(coverWidth)
            ctx.setLineJoin(.round)
            for stroke in strokes {
                guard let first = stroke.first else { continue }
                if stroke.count == 1 {
                    let r = coverWidth / 2
                    ctx.fillEllipse(in: CGRect(x: first.x - r, y: first.y - r, width: r * 2, height: r * 2))
                    continue
                }
                ctx.move(to: first)
                for p in stroke.dropFirst() { ctx.addLine(to: p) }
                ctx.strokePath()
            }
        }
        var covered = 0
        for i in 0..<ink.count where masks.shape[i] > 127 && ink[i] > 127 {
            covered += 1
        }
        let recall = masks.shapePixelCount > 0 ? Double(covered) / Double(masks.shapePixelCount) : 0
        let score = 0.45 * precision + 0.55 * recall
        return (precision, recall, score)
    }

    static func stars(for score: Double) -> Int {
        if score >= 0.8 { return 3 }
        if score >= 0.6 { return 2 }
        if score >= 0.35 { return 1 }
        return 0
    }

    static func checkpointHits(_ checkpoints: [CGPoint], strokes: [[CGPoint]], radius: CGFloat = 28) -> Set<Int> {
        var hits = Set<Int>()
        for (i, c) in checkpoints.enumerated() {
            let hit = strokes.contains { stroke in
                stroke.contains { hypot($0.x - c.x, $0.y - c.y) < radius }
            }
            if hit { hits.insert(i) }
        }
        return hits
    }

    static func evaluate(word: FavoriteWord, guide: LetterGuide, masks: GuideMasks, strokes: [[CGPoint]]) -> TraceResult {
        evaluate(letter: nil, title: word.latin, display: word.text, hasDots: true, isAlef: false,
                 guide: guide, masks: masks, strokes: strokes)
    }

    static func evaluate(letter: Letter, guide: LetterGuide, masks: GuideMasks, strokes: [[CGPoint]]) -> TraceResult {
        evaluate(letter: letter, title: letter.name, display: letter.char,
                 hasDots: !letter.dots.hasPrefix("No"), isAlef: letter.char == "ا",
                 guide: guide, masks: masks, strokes: strokes)
    }

    private static func evaluate(letter: Letter?, title: String, display: String, hasDots: Bool, isAlef: Bool,
                                 guide: LetterGuide, masks: GuideMasks, strokes: [[CGPoint]]) -> TraceResult {
        let m = measure(strokes, masks: masks)
        let hits = checkpointHits(guide.checkpoints, strokes: strokes)

        var feedback: [TraceFeedback] = []
        if let main = strokes.max(by: { $0.count < $1.count }), let a = main.first, let b = main.last {
            if isAlef {
                feedback.append(a.y <= b.y
                    ? TraceFeedback(good: true, text: "You drew it from the top down.")
                    : TraceFeedback(good: false, text: "Try starting at the top and pulling down."))
            } else {
                feedback.append(a.x >= b.x - 20
                    ? TraceFeedback(good: true, text: "You started on the right and moved left.")
                    : TraceFeedback(good: false, text: "Farsi flows right to left. Start on the right side."))
            }
        }
        feedback.append(m.precision >= 0.85
            ? TraceFeedback(good: true, text: "You stayed inside the shape.")
            : TraceFeedback(good: false, text: "Some ink wandered off the shape. Slow down at the curves."))
        feedback.append(m.recall >= 0.8
            ? TraceFeedback(good: true, text: hasDots ? "You covered the whole letter, dots included." : "You covered the whole letter.")
            : TraceFeedback(good: false, text: hasDots ? "A part is missing. Check the ends and the dots." : "A part is missing. Check both ends."))

        return TraceResult(letter: letter,
                           title: title,
                           display: display,
                           inkWidth: masks.inkWidth,
                           precision: m.precision,
                           recall: m.recall,
                           score: m.score,
                           stars: stars(for: m.score),
                           checkpointsHit: hits.count,
                           checkpointsTotal: guide.checkpoints.count,
                           strokes: strokes,
                           feedback: feedback)
    }
}
