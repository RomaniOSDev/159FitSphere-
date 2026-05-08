import SwiftUI

enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case timer
    case train
    case achievements
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"
        case .timer:
            return "Timer"
        case .train:
            return "Train"
        case .achievements:
            return "Awards"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .timer:
            return "timer"
        case .train:
            return "figure.run"
        case .achievements:
            return "trophy.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var tab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            AppChromeBackground()
                .ignoresSafeArea(edges: .all)

            Group {
                switch tab {
                case .home:
                    HomeView(selectedTab: $tab)
                case .timer:
                    Feature1View()
                case .train:
                    TrainContainerView()
                case .achievements:
                    AchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 78)

            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 8) {
            ForEach(MainTab.allCases) { item in
                let isSelected = tab == item

                Button {
                    HapticSound.tapLight()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tab = item
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))

                        Text(item.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(FitSphereStyle.primaryButtonGradient)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
                                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 10, y: 2)
                            }
                        }
                    }
                }
                .buttonStyle(MainTabPressStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.98),
                            Color.appSurface.opacity(0.72),
                            Color.appBackground.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.appAccent.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.45), radius: 24, x: 0, y: 12)
                .shadow(color: Color.appPrimary.opacity(0.12), radius: 30, x: 0, y: 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

private struct MainTabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
