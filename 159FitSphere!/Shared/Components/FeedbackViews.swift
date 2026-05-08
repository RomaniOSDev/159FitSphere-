import Combine
import SwiftUI

struct SuccessFlashView: View {
    let isVisible: Bool

    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 56, weight: .semibold))
            .foregroundStyle(Color.appAccent, Color.appSurface.opacity(0.25))
            .scaleEffect(scale)
            .opacity(opacity)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .onChange(of: isVisible) { newValue in
                guard newValue else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        opacity = 0
                        scale = 0.85
                    }
                    return
                }
                scale = 0.6
                opacity = 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    scale = 1.0
                    opacity = 1
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        opacity = 0
                        scale = 0.92
                    }
                }
            }
    }
}

struct AchievementBannerView: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rosette")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.appAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fitSpherePanel(cornerRadius: 16, elevated: true)
        .padding(.horizontal, 12)
    }
}

struct SoftHintBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appPrimary.opacity(0.9))

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .fitSpherePanel(cornerRadius: 16, elevated: true)
        .padding(.horizontal, 12)
    }
}
