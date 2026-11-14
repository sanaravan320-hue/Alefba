import SwiftUI

// MARK: - Ink box (card with ink outline and optional hard shadow)

struct InkBox: ViewModifier {
    var fill: Color
    var radius: CGFloat = 22
    var shadow: CGFloat = 0
    var dashed: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(Ink.ink, style: StrokeStyle(lineWidth: 2, dash: dashed ? [6, 5] : [])))
            .background(shape.fill(Ink.ink).offset(x: shadow, y: shadow).opacity(shadow > 0 ? 1 : 0))
    }
}

extension View {
    func inkBox(_ fill: Color, radius: CGFloat = 22, shadow: CGFloat = 0, dashed: Bool = false) -> some View {
        modifier(InkBox(fill: fill, radius: radius, shadow: shadow, dashed: dashed))
    }
}

// MARK: - Buttons

struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, accent }
    var kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    init(kind: Kind = .secondary) {
        self.kind = kind
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.body(17, .semibold))
            .foregroundStyle(kind == .primary ? Ink.card : Ink.ink)
            .padding(.horizontal, 22)
            .frame(minHeight: 48)
            .background(Capsule().fill(background))
            .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: 2))
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var background: Color {
        switch kind {
        case .primary: return Ink.ink
        case .secondary: return Ink.card
        case .accent: return Ink.saffron
        }
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.title
            configuration.icon
        }
    }
}

struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(AppFont.body(16, .semibold))
            }
            .foregroundStyle(Ink.ink)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shapes

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let raw: [(CGFloat, CGFloat)] = [
            (12, 2.8), (14.8, 8.6), (21.2, 9.5), (16.6, 14), (17.7, 20.3),
            (12, 17.3), (6.3, 20.3), (7.4, 14), (2.8, 9.5), (9.2, 8.6)
        ]
        let points = raw.map { CGPoint(x: rect.minX + $0.0 / 24 * rect.width, y: rect.minY + $0.1 / 24 * rect.height) }
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }
}

struct InkDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x / 24 * rect.width, y: rect.minY + y / 24 * rect.height)
        }
        var path = Path()
        path.move(to: p(12, 3))
        path.addCurve(to: p(18, 14), control1: p(15, 7.2), control2: p(18, 10.6))
        path.addArc(center: p(12, 14), radius: 6 / 24 * rect.width,
                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        path.addCurve(to: p(12, 3), control1: p(6, 10.6), control2: p(9, 7.2))
        path.closeSubpath()
        return path
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct DashedRule: View {
    var color: Color = Ink.rule
    var body: some View {
        Line()
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            .frame(height: 2)
    }
}

// MARK: - Small pieces

struct StarRow: View {
    var filled: Int
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: size * 0.18) {
            ForEach(0..<3, id: \.self) { i in
                StarShape()
                    .fill(i < filled ? Ink.saffron : Color.clear)
                    .overlay(StarShape().stroke(Ink.ink, style: StrokeStyle(lineWidth: max(1.5, size / 14), lineJoin: .round)))
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) of 3 stars")
    }
}

struct SingleStar: View {
    var size: CGFloat = 22
    var body: some View {
        StarShape()
            .fill(Ink.saffron)
            .overlay(StarShape().stroke(Ink.ink, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct InkDrop: View {
    var size: CGFloat = 22
    var body: some View {
        InkDropShape()
            .fill(Ink.lapis)
            .overlay(InkDropShape().stroke(Ink.ink, lineWidth: 1.6))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct Chip<Icon: View>: View {
    let text: String
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(text).font(AppFont.body(16, .semibold))
        }
        .foregroundStyle(Ink.ink)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Capsule().fill(Ink.card))
        .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: 2))
    }
}

struct Pill: View {
    let text: String
    var dark: Bool = true

    var body: some View {
        Text(text)
            .font(AppFont.body(12, .bold))
            .foregroundStyle(dark ? Ink.card : Ink.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Capsule().fill(dark ? Ink.ink : Color.clear))
            .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: dark ? 0 : 1.5))
    }
}

struct ProgressBar: View {
    var value: Double
    var fill: Color = Ink.turquoise

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Ink.paper)
                Capsule().fill(fill)
                    .frame(width: CGFloat(max(0, min(1, value))) * geo.size.width)
            }
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Ink.ink, lineWidth: 2))
        }
        .frame(height: 14)
        .accessibilityElement()
        .accessibilityValue("\(Int(value * 100)) percent")
    }
}

struct ItalianHint: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("IT")
                .font(AppFont.body(11, .bold))
                .foregroundStyle(Ink.card)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 6).fill(Ink.ink))
                .accessibilityLabel("Italian hint")
            Text(text)
                .font(AppFont.body(15))
                .foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Persian letters with their sound written underneath, read right to left.
struct LetterSoundRow: View {
    let letters: [Letter]
    var letterSize: CGFloat = 28
    var soundSize: CGFloat = 13
    var spacing: CGFloat = 8
    var minPairWidth: CGFloat = 22
    var isDimmed: (Letter) -> Bool = { _ in false }

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(letters.reversed()) { letter in
                VStack(spacing: 0) {
                    Text(letter.char)
                        .font(AppFont.letter(letterSize))
                        .foregroundStyle(isDimmed(letter) ? Ink.dim : Ink.ink)
                    Text(letter.sound)
                        .font(AppFont.body(soundSize, .bold))
                        .foregroundStyle(isDimmed(letter) ? Ink.dimText : Ink.lapis)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(minWidth: minPairWidth)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(letters.map { "\($0.name), sounds like \($0.sound)" }.joined(separator: "; "))
    }
}

struct FormsRow: View {
    let letter: Letter
    var size: CGFloat = 26

    var body: some View {
        VStack(spacing: 0) {
            DashedRule()
            HStack(spacing: 4) {
                ForEach(letter.forms, id: \.label) { form in
                    VStack(spacing: 2) {
                        Text(form.text)
                            .font(AppFont.letter(size))
                            .foregroundStyle(Ink.ink)
                            .frame(height: size * 1.55)
                        Text(form.label)
                            .font(AppFont.body(12))
                            .foregroundStyle(Ink.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)
            DashedRule()
        }
    }
}

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Ink.paper
            Canvas { context, size in
                var rng = SeededRandom(seed: 7)
                let count = Int(size.width * size.height / 260)
                let grain = Color(hex: 0x6B5A3A)
                for _ in 0..<count {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let r = 0.4 + rng.next() * 0.9
                    let a = 0.03 + rng.next() * 0.06
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                                 with: .color(grain.opacity(Double(a))))
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = (seed &* 0x9E37_79B9_7F4A_7C15) | 1
    }

    mutating func next() -> CGFloat {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return CGFloat(state % 10_000) / 10_000
    }
}
