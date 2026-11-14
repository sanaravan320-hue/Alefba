import SwiftUI
import PencilKit

/// PencilKit canvas with a transparent background, so the guide shows through.
///
/// PencilKit's pen can't draw wider than about 25 pt, but letters need thicker ink.
/// So when the ink is wider than the pen allows, the canvas is drawn smaller and
/// scaled up by `zoom`: the strokes then look exactly as thick as the letter.
/// Points in the drawing are in the small canvas's coordinates: multiply by `zoom`.
struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    /// Bump this to push `drawing` into the canvas (clear / undo).
    var resetToken: Int
    var pencilOnly: Bool
    /// Ink width in on-screen points.
    var inkWidth: CGFloat
    var onChange: (PKDrawing) -> Void

    static var maxPenWidth: CGFloat {
        PKInkingTool.InkType.pen.validWidthRange.upperBound * 0.95
    }

    /// How much the canvas is scaled up to reach `inkWidth`.
    static func zoom(for inkWidth: CGFloat) -> CGFloat {
        max(1, (inkWidth / maxPenWidth).rounded(.up))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ScaledCanvasHost {
        let host = ScaledCanvasHost()
        let canvas = host.canvas
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput
        apply(width: inkWidth, to: host)
        context.coordinator.lastToken = resetToken
        context.coordinator.lastInkWidth = inkWidth
        return host
    }

    func updateUIView(_ host: ScaledCanvasHost, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.lastToken != resetToken {
            context.coordinator.lastToken = resetToken
            host.canvas.drawing = drawing
        }
        host.canvas.drawingPolicy = pencilOnly ? .pencilOnly : .anyInput
        if context.coordinator.lastInkWidth != inkWidth {
            context.coordinator.lastInkWidth = inkWidth
            apply(width: inkWidth, to: host)
        }
    }

    private func apply(width: CGFloat, to host: ScaledCanvasHost) {
        let zoom = Self.zoom(for: width)
        host.zoom = zoom
        host.canvas.tool = PKInkingTool(.pen, color: UIColor(Ink.ink), width: width / zoom)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvas
        var lastToken = 0
        var lastInkWidth: CGFloat = 0

        init(_ parent: PencilCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawing = canvasView.drawing
            DispatchQueue.main.async {
                self.parent.drawing = drawing
                self.parent.onChange(drawing)
            }
        }
    }
}

/// Holds the PKCanvasView at 1/zoom size, scaled up by zoom to fill the host.
final class ScaledCanvasHost: UIView {
    let canvas = PKCanvasView()

    var zoom: CGFloat = 1 {
        didSet { if zoom != oldValue { setNeedsLayout() } }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.isScrollEnabled = false
        canvas.showsVerticalScrollIndicator = false
        canvas.showsHorizontalScrollIndicator = false
        addSubview(canvas)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        canvas.transform = .identity
        canvas.bounds = CGRect(x: 0, y: 0, width: bounds.width / zoom, height: bounds.height / zoom)
        canvas.center = CGPoint(x: bounds.midX, y: bounds.midY)
        canvas.transform = CGAffineTransform(scaleX: zoom, y: zoom)
        // Render at full sharpness despite the scale-up.
        canvas.contentScaleFactor = (window?.screen.scale ?? UIScreen.main.scale) * zoom
    }
}
