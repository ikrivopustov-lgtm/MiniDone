import SwiftUI

struct BrandMarkView: View {
    var size: CGFloat = 18
    var showsAccent = true

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height)
            let stroke = max(1.6, scale * 0.10)
            var check = Path()
            check.move(to: CGPoint(x: scale * 0.13, y: scale * 0.33))
            check.addLine(to: CGPoint(x: scale * 0.21, y: scale * 0.43))
            check.addLine(to: CGPoint(x: scale * 0.34, y: scale * 0.24))

            context.stroke(
                check,
                with: .color(AppStyle.primaryText),
                style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
            )

            if showsAccent {
                context.fill(
                    Path(ellipseIn: CGRect(x: scale * 0.13, y: scale * 0.58, width: scale * 0.13, height: scale * 0.13)),
                    with: .color(AppStyle.green)
                )
            }

            for y in [0.34, 0.53, 0.70] {
                var line = Path()
                line.move(to: CGPoint(x: scale * 0.44, y: scale * y))
                line.addLine(to: CGPoint(x: scale * 0.85, y: scale * y))
                context.stroke(
                    line,
                    with: .color(AppStyle.secondaryText),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
            }
        }
        .frame(width: size, height: size)
    }
}
