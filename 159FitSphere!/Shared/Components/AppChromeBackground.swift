import SwiftUI

struct AppChromeBackground: View {
    var body: some View {
        ZStack {
            FitSphereStyle.screenBaseGradient

            FitSphereStyle.screenAccentOrbPrimary
                .ignoresSafeArea()

            FitSphereStyle.screenAccentOrbSecondary
                .ignoresSafeArea()

            // Soft vignette for depth
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Canvas { context, size in
                let grid: CGFloat = 32
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += grid
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += grid
                }
                context.stroke(
                    path,
                    with: .color(Color.appAccent.opacity(0.08)),
                    lineWidth: 1
                )
            }
        }
        .ignoresSafeArea()
    }
}
