import SwiftUI

private struct ShakeEffectModifier: GeometryEffect {
    var travelDistance: CGFloat = 8
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travelDistance * sin(shakes * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

extension View {
    func shake(trigger: CGFloat) -> some View {
        modifier(ShakeEffectModifier(shakes: trigger))
    }
}
