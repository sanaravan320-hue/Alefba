import CoreGraphics
import CoreText
import Foundation

/// A cubic Bézier segment, used for hand-drawn guides with a known stroke order.
struct CubicSegment {
    let p0: CGPoint
    let c1: CGPoint
    let c2: CGPoint
    let p1: CGPoint

    func point(at t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let a = mt * mt * mt
        let b = 3 * mt * mt * t
        let c = 3 * mt * t * t
        let d = t * t * t
        return CGPoint(x: a * p0.x + b * c1.x + c * c2.x + d * p1.x,
                       y: a * p0.y + b * c1.y + c * c2.y + d * p1.y)
    }
}

/// The shape he traces, in a fixed 700 × 440 "guide space" (y points down).
///
/// Two kinds:
/// - authored (bowl family for now): a hand-drawn centre line with stroke order,
///   checkpoints, a start point and numbered dots;
/// - glyph: the letter's outline taken from Vazirmatn, for every other letter.
struct LetterGuide {
    static let space = CGSize(width: 700, height: 440)
    static let dotRadius: CGFloat = 17

    /// Filled shape, used to draw the faint guide and to score.
    let outline: CGPath
    /// Centre line of the main stroke (authored guides only).
    let body: CGPath?
    let bodySegments: [CubicSegment]
    let dots: [CGPoint]
    let checkpoints: [CGPoint]
    let start: CGPoint?
    let steps: [String]

    var isAuthored: Bool { body != nil }
    var expectedStrokes: Int { isAuthored ? 1 + dots.count : steps.count }

    private static var cache: [String: LetterGuide] = [:]

    static func make(for letter: Letter) -> LetterGuide {
        if let cached = cache[letter.char] { return cached }
        let guide = BowlGuide.guide(for: letter) ?? glyphGuide(for: letter)
        cache[letter.char] = guide
        return guide
    }

    /// Guide for a whole word or phrase, shaped and joined by the font.
    static func make(forWord word: FavoriteWord) -> LetterGuide {
        let key = "word:" + word.id
        if let cached = cache[key] { return cached }
        let outline = textPath(word.text, fontName: "Vazirmatn-Medium") ?? CGMutablePath()
        let guide = LetterGuide(outline: outline, body: nil, bodySegments: [], dots: [],
                                checkpoints: [], start: nil,
                                steps: ["Write the body of each part, right to left",
                                        "Add the dots and small marks last"])
        cache[key] = guide
        return guide
    }

    private static func textPath(_ text: String, fontName: String) -> CGPath? {
        let font = CTFontCreateWithName(fontName as CFString, 300, nil)
        let attributed = NSAttributedString(string: text,
                                            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
        let line = CTLineCreateWithAttributedString(attributed)
        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return nil }
        let raw = CGMutablePath()
        for run in runs {
            let attributes = CTRunGetAttributes(run) as NSDictionary
            var runFont = font
            if let value = attributes[kCTFontAttributeName as String] {
                runFont = value as! CTFont
            }
            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            for i in 0..<count {
                if let glyphPath = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                    raw.addPath(glyphPath, transform: CGAffineTransform(translationX: positions[i].x, y: positions[i].y))
                }
            }
        }
        let box = raw.boundingBoxOfPath
        guard box.width > 0, box.height > 0 else { return nil }
        let scale = min(640 / box.width, 330 / box.height, 1.1)
        var transform = CGAffineTransform(translationX: space.width / 2, y: space.height / 2)
            .scaledBy(x: scale, y: -scale)
            .translatedBy(x: -box.midX, y: -box.midY)
        return raw.copy(using: &transform)
    }

    // MARK: Glyph guides

    private static func glyphGuide(for letter: Letter) -> LetterGuide {
        let outline = glyphPath(letter.char, fontName: "Vazirmatn-Medium")
            ?? glyphPath(letter.char, fontName: "GeezaPro")
            ?? CGMutablePath()
        var steps: [String]
        if letter.char == "ا" {
            steps = ["One stroke, from the top down"]
        } else {
            steps = ["Trace the shape, starting on the right"]
        }
        if !letter.dots.hasPrefix("No") {
            steps.append("Finish with: \(letter.dots.lowercased())")
        }
        return LetterGuide(outline: outline, body: nil, bodySegments: [], dots: [],
                           checkpoints: [], start: nil, steps: steps)
    }

    private static func glyphPath(_ char: String, fontName: String) -> CGPath? {
        let font = CTFontCreateWithName(fontName as CFString, 300, nil)
        var units = Array(char.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: units.count)
        guard CTFontGetGlyphsForCharacters(font, &units, &glyphs, units.count),
              let glyph = glyphs.first, glyph != 0,
              let raw = CTFontCreatePathForGlyph(font, glyph, nil) else { return nil }
        let box = raw.boundingBoxOfPath
        guard box.width > 0, box.height > 0 else { return nil }
        // Same scale for every letter (so sizes compare), shrunk only if it wouldn't fit.
        let scale = min(520 / box.width, 330 / box.height, 1.25)
        var transform = CGAffineTransform(translationX: space.width / 2, y: space.height / 2)
            .scaledBy(x: scale, y: -scale)
            .translatedBy(x: -box.midX, y: -box.midY)
        return raw.copy(using: &transform)
    }
}

/// Hand-drawn guide for ب پ ت ث: one bowl, different dots.
enum BowlGuide {
    static let strokeWidth: CGFloat = 46

    static let segments: [CubicSegment] = [
        CubicSegment(p0: CGPoint(x: 585, y: 168), c1: CGPoint(x: 596, y: 214),
                     c2: CGPoint(x: 588, y: 258), p1: CGPoint(x: 548, y: 274)),
        CubicSegment(p0: CGPoint(x: 548, y: 274), c1: CGPoint(x: 460, y: 304),
                     c2: CGPoint(x: 240, y: 306), p1: CGPoint(x: 150, y: 282)),
        CubicSegment(p0: CGPoint(x: 150, y: 282), c1: CGPoint(x: 112, y: 272),
                     c2: CGPoint(x: 96, y: 246), p1: CGPoint(x: 106, y: 208))
    ]

    /// Dots in the order he should draw them, with the step text for each.
    static func dots(for char: String) -> [(CGPoint, String)]? {
        switch char {
        case "ب":
            return [(CGPoint(x: 350, y: 362), "Add the dot below")]
        case "پ":
            return [(CGPoint(x: 378, y: 356), "Add the right dot below"),
                    (CGPoint(x: 322, y: 356), "Add the left dot below"),
                    (CGPoint(x: 350, y: 402), "Add the bottom dot")]
        case "ت":
            return [(CGPoint(x: 378, y: 212), "Add the right dot"),
                    (CGPoint(x: 322, y: 212), "Add the left dot, level with it")]
        case "ث":
            return [(CGPoint(x: 378, y: 222), "Add the right dot"),
                    (CGPoint(x: 322, y: 222), "Add the left dot"),
                    (CGPoint(x: 350, y: 172), "Add the top dot")]
        default:
            return nil
        }
    }

    static func guide(for letter: Letter) -> LetterGuide? {
        guard let dotSteps = dots(for: letter.char) else { return nil }
        let dots = dotSteps.map { $0.0 }

        let body = CGMutablePath()
        body.move(to: segments[0].p0)
        for s in segments {
            body.addCurve(to: s.p1, control1: s.c1, control2: s.c2)
        }

        let outline = CGMutablePath()
        outline.addPath(body.copy(strokingWithWidth: strokeWidth, lineCap: .round, lineJoin: .round, miterLimit: 10))
        let r = LetterGuide.dotRadius
        for d in dots {
            outline.addEllipse(in: CGRect(x: d.x - r, y: d.y - r, width: r * 2, height: r * 2))
        }

        return LetterGuide(outline: outline,
                           body: body,
                           bodySegments: segments,
                           dots: dots,
                           checkpoints: checkpoints(),
                           start: segments[0].p0,
                           steps: ["Draw the bowl, right to left"] + dotSteps.map { $0.1 })
    }

    static func polyline(samplesPerSegment n: Int = 40) -> [CGPoint] {
        var points: [CGPoint] = [segments[0].p0]
        for s in segments {
            for i in 1...n {
                points.append(s.point(at: CGFloat(i) / CGFloat(n)))
            }
        }
        return points
    }

    /// Five points spread along the bowl that light up as he passes them.
    static func checkpoints() -> [CGPoint] {
        let points = polyline()
        var lengths: [CGFloat] = [0]
        for i in 1..<points.count {
            lengths.append(lengths[i - 1] + hypot(points[i].x - points[i - 1].x, points[i].y - points[i - 1].y))
        }
        let total = lengths.last ?? 1
        return [0.16, 0.36, 0.54, 0.72, 0.9].map { fraction in
            let target = total * fraction
            let index = lengths.firstIndex { $0 >= target } ?? (points.count - 1)
            return points[index]
        }
    }
}

/// Maps guide space onto the canvas on screen (aspect fit, centred).
struct GuideFit: Equatable {
    var scale: CGFloat
    var offset: CGPoint

    init(size: CGSize) {
        let s = max(0.01, min(size.width / LetterGuide.space.width, size.height / LetterGuide.space.height))
        scale = s
        offset = CGPoint(x: (size.width - LetterGuide.space.width * s) / 2,
                         y: (size.height - LetterGuide.space.height * s) / 2)
    }

    var transform: CGAffineTransform {
        CGAffineTransform(translationX: offset.x, y: offset.y).scaledBy(x: scale, y: scale)
    }

    func toView(_ p: CGPoint) -> CGPoint {
        CGPoint(x: offset.x + p.x * scale, y: offset.y + p.y * scale)
    }

    func toGuide(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - offset.x) / scale, y: (p.y - offset.y) / scale)
    }
}
