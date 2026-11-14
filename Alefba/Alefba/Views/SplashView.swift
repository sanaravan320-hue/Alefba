import SwiftUI

/// Plays right after the system launch screen: same background and logo,
/// so it looks continuous, then confetti pops out and it fades into Home.
struct SplashView: View {
    @State private var popped = false

    private struct Piece: Identifiable {
        let id: Int
        let offset: CGSize
        let color: Color
        let star: Bool
        let size: CGFloat
        let rotation: Double
    }

    private let pieces: [Piece] = {
        let colors: [Color] = [Color(hex: 0x8E9FD8), Color(hex: 0xEB8F80), Color(hex: 0xA9CFA6),
                               Color(hex: 0xF2CF72), Color(hex: 0x9CC5C9)]
        var rng = SeededRandom(seed: 11)
        return (0..<26).map { i in
            let angle = Double(i) / 26 * 2 * .pi + Double(rng.next()) * 0.3
            let distance = 260 + Double(rng.next()) * 170
            return Piece(id: i,
                         offset: CGSize(width: CGFloat(cos(angle) * distance * 1.35),
                                        height: CGFloat(sin(angle) * distance)),
                         color: colors[i % colors.count],
                         star: i % 3 == 0,
                         size: 14 + rng.next() * 16,
                         rotation: Double(rng.next()) * 120 - 60)
        }
    }()

    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()

            ForEach(pieces) { piece in
                Group {
                    if piece.star {
                        StarShape().fill(piece.color)
                    } else {
                        Circle().fill(piece.color)
                    }
                }
                .frame(width: piece.size, height: piece.size)
                .rotationEffect(.degrees(popped ? piece.rotation : 0))
                .offset(popped ? piece.offset : .zero)
                .scaleEffect(popped ? 1 : 0.2)
                .opacity(popped ? 1 : 0)
            }

            Image("LaunchLogo")
                .scaleEffect(popped ? 1.04 : 1)
                .accessibilityLabel("Alefba")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.62).delay(0.1)) {
                popped = true
            }
        }
    }
}
