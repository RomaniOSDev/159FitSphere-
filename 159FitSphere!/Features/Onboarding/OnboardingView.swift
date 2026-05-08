import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var page = 0

    var body: some View {
        ZStack {
            AppChromeBackground()

            VStack(spacing: 0) {
                headerBar

                TabView(selection: $page) {
                    OnboardingPageView(
                        illustration: { OnboardingIllustrationTimer() },
                        headline: "Intervals that fit you",
                        text: "Tune work, rest, and rounds — save Tabata, EMOM, or your own presets and start in one tap."
                    )
                    .tag(0)

                    OnboardingPageView(
                        illustration: { OnboardingIllustrationRoutine() },
                        headline: "Routines, your way",
                        text: "Build categories, exercises, and quick notes. Track what’s done and keep tomorrow’s focus visible."
                    )
                    .tag(1)

                    OnboardingPageView(
                        illustration: { OnboardingIllustrationProgress() },
                        headline: "See the momentum",
                        text: "Weekly goals, history, and achievements stay on device — export anytime as JSON or a screen-ready report."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 540)

                pageIndicators
                    .padding(.top, 8)

                Button {
                    HapticSound.tapLight()
                    if page < 2 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            page += 1
                        }
                    } else {
                        HapticSound.impactMedium()
                        store.markOnboardingSeen()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(page < 2 ? "Continue" : "Enter FitSphere")
                            .font(.headline.weight(.bold))
                        Image(systemName: page < 2 ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                            .font(.title3)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .fitSpherePrimaryButton(cornerRadius: 18)
                }
                .buttonStyle(OnboardingButtonScaleStyle())
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Spacer(minLength: 28)
            }
        }
    }

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(FitSphereStyle.primaryButtonGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)
                Image(systemName: "figure.run")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("FitSphere")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Train smarter on your terms")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer(minLength: 0)

            Button {
                HapticSound.tapLight()
                store.markOnboardingSeen()
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .fitSphereInsetPanel(cornerRadius: 12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Group {
                    if index == page {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(FitSphereStyle.primaryButtonGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                            )
                            .frame(width: 36, height: 8)
                            .shadow(color: Color.appPrimary.opacity(0.45), radius: 8, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.appTextSecondary.opacity(0.22))
                            .frame(width: 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: page)
                .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Page

private struct OnboardingPageView<Illustration: View>: View {
    @ViewBuilder let illustration: () -> Illustration
    let headline: String
    let text: String

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 18) {
            illustrationStage
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: appeared)

            VStack(alignment: .leading, spacing: 12) {
                Text(headline)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fitSpherePanel(cornerRadius: 22, elevated: false)
            .padding(.horizontal, 20)
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05), value: appeared)
        }
        .padding(.bottom, 8)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }

    private var illustrationStage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.92),
                    Color.appAccent.opacity(0.68),
                    Color.appPrimary.opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 160, height: 160)
                .offset(x: 110, y: -70)
                .blur(radius: 0.5)

            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 90, height: 90)
                .offset(x: -100, y: 90)

            illustration()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 288)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 26, x: 0, y: 16)
        .shadow(color: Color.appPrimary.opacity(0.22), radius: 32, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
}

// MARK: - Illustrations

private struct OnboardingIllustrationTimer: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 11
                )
                .frame(width: 176, height: 176)
                .shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5, height: 56)
                .offset(y: -26)
                .rotationEffect(.degrees(-38))
                .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.95), Color.appAccent.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5, height: 46)
                .offset(y: -20)
                .rotationEffect(.degrees(52))
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.08)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 22
                    )
                )
                .frame(width: 22, height: 22)

            Image(systemName: "timer")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .offset(y: 118)
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingIllustrationRoutine: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.5)
                )
                .frame(width: 236, height: 152)
                .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.45 + Double(index) * 0.1),
                                        Color.white.opacity(0.18)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 56, height: 16)
                            .shadow(color: Color.black.opacity(0.15), radius: 3, y: 1)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(width: 236, height: 152)

            Image(systemName: "checklist")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .offset(x: 100, y: -62)
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingIllustrationProgress: View {
    private let dots: [CGPoint] = [
        CGPoint(x: -72, y: 38),
        CGPoint(x: -8, y: 2),
        CGPoint(x: 58, y: -32)
    ]

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 18, y: 152))
                path.addQuadCurve(to: CGPoint(x: 214, y: 32), control: CGPoint(x: 118, y: 188))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.85),
                        Color.appAccent.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 7, lineCap: .round)
            )
            .shadow(color: Color.appAccent.opacity(0.35), radius: 10, y: 4)

            ForEach(Array(dots.enumerated()), id: \.offset) { _, point in
                ZStack {
                    Circle()
                        .fill(Color.appPrimary.opacity(0.45))
                        .frame(width: 22, height: 22)
                        .blur(radius: 4)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 15, height: 15)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
                }
                .offset(x: point.x, y: point.y)
            }

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .offset(y: 112)
        }
        .frame(width: 248, height: 200)
        .accessibilityHidden(true)
    }
}

private struct OnboardingButtonScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
