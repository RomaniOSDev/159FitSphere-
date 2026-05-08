import SwiftUI

// MARK: - Gradients & materials

enum FitSphereStyle {

    /// Deep ambient background (orbs + base tones)
    static var screenBaseGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appSurface.opacity(0.35),
                Color.appBackground.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var screenAccentOrbPrimary: RadialGradient {
        RadialGradient(
            colors: [
                Color.appPrimary.opacity(0.28),
                Color.appPrimary.opacity(0.06),
                Color.clear
            ],
            center: .topTrailing,
            startRadius: 20,
            endRadius: 280
        )
    }

    static var screenAccentOrbSecondary: RadialGradient {
        RadialGradient(
            colors: [
                Color.appAccent.opacity(0.22),
                Color.appAccent.opacity(0.05),
                Color.clear
            ],
            center: .bottomLeading,
            startRadius: 30,
            endRadius: 320
        )
    }

    /// Raised card face — subtle volume
    static var cardFaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.95),
                Color.appSurface.opacity(0.42),
                Color.appBackground.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardEdgeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                Color.appAccent.opacity(0.28),
                Color.appPrimary.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary.opacity(0.98),
                Color.appPrimary.opacity(0.65),
                Color.appAccent.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButtonEdge: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.35),
                Color.white.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - View modifiers

private struct FitSpherePanelModifier: ViewModifier {
    var cornerRadius: CGFloat
    var elevated: Bool

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FitSphereStyle.cardFaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(FitSphereStyle.cardEdgeGradient, lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(elevated ? 0.42 : 0.24),
                        radius: elevated ? 16 : 8,
                        x: 0,
                        y: elevated ? 10 : 5
                    )
                    .shadow(
                        color: Color.appPrimary.opacity(elevated ? 0.14 : 0.07),
                        radius: elevated ? 22 : 12,
                        x: 0,
                        y: 4
                    )
            }
    }
}

private struct FitSphereInsetPanelModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appBackground.opacity(0.75),
                                Color.appSurface.opacity(0.32)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.06),
                                        Color.appAccent.opacity(0.14)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 4)
            }
    }
}

private struct FitSphereCapsuleChipModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(0.92),
                                Color.appBackground.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(FitSphereStyle.cardEdgeGradient, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.32), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.appAccent.opacity(0.08), radius: 12, y: 0)
            }
    }
}

extension View {

    /// Standard floating card (shadows + gradient fill + lit edge).
    func fitSpherePanel(cornerRadius: CGFloat = 16, elevated: Bool = true) -> some View {
        modifier(FitSpherePanelModifier(cornerRadius: cornerRadius, elevated: elevated))
    }

    /// Softer “inset” surface for nested blocks / list rows.
    func fitSphereInsetPanel(cornerRadius: CGFloat = 14) -> some View {
        modifier(FitSphereInsetPanelModifier(cornerRadius: cornerRadius))
    }

    func fitSpherePrimaryButton(cornerRadius: CGFloat = 16) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FitSphereStyle.primaryButtonGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(FitSphereStyle.primaryButtonEdge, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.38), radius: 14, x: 0, y: 8)
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 18, x: 0, y: 4)
            }
    }

    func fitSphereCapsuleChip() -> some View {
        modifier(FitSphereCapsuleChipModifier())
    }
}
