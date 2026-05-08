import SwiftUI

private struct MosaicSlide: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let colors: [Color]
}

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var selectedTab: MainTab

    @State private var showHistory = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var mosaicSlides: [MosaicSlide] {
        [
            MosaicSlide(title: "Strength", icon: "figure.strengthtraining.traditional", colors: [Color.purple.opacity(0.85), Color.appPrimary]),
            MosaicSlide(title: "Cardio", icon: "figure.run", colors: [Color.orange.opacity(0.9), Color.red.opacity(0.7)]),
            MosaicSlide(title: "Mobility", icon: "figure.walk", colors: [Color.mint.opacity(0.85), Color.teal.opacity(0.75)]),
            MosaicSlide(title: "Focus", icon: "scope", colors: [Color.cyan.opacity(0.8), Color.appAccent]),
            MosaicSlide(title: "Recovery", icon: "leaf.fill", colors: [Color.green.opacity(0.75), Color.appSurface])
        ]
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var heroSubtitle: String {
        if store.streakDays > 0 {
            return "You're on a \(store.streakDays)-day streak — stay in rhythm."
        }
        if store.sessionsCompleted == 0 {
            return "Start a timer or routine to log your first session."
        }
        return store.computePlanSummaryLine()
    }

    private var nextRoutineName: String {
        if let r = store.routines.first(where: { $0.isFullyCompleted == false }) {
            return r.name
        }
        return store.routines.first?.name ?? "Create a routine"
    }

    private var unlockedAchievements: Int {
        AchievementCatalog.all.filter { $0.isUnlocked(store: store) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroBanner

                    inspirationalStrip

                    sectionLabel("Dashboard")
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        streakCard
                        weeklyGoalCard
                        timerQuickCard
                        trainCard
                        statsCard
                        achievementsCard
                    }

                    if store.customTimerPresets.isEmpty == false {
                        sectionLabel("Saved timer presets")
                        presetsStrip
                    }

                    sectionLabel("Ideas")
                    tipCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticSound.tapLight()
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                    .accessibilityLabel("Session history")
                }
            }
            .sheet(isPresented: $showHistory) {
                NavigationStack {
                    SessionHistoryView()
                        .environmentObject(store)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    HapticSound.tapLight()
                                    showHistory = false
                                }
                                .foregroundStyle(Color.appPrimary)
                            }
                        }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.appTextSecondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.95),
                    Color.appAccent.opacity(0.75),
                    Color.appPrimary.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative “illustrations” — layered SF Symbols
            GeometryReader { geo in
                ZStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: min(geo.size.width * 0.38, 160), weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.14))
                        .position(x: geo.size.width * 0.78, y: geo.size.height * 0.38)
                        .rotationEffect(.degrees(-8))

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: min(geo.size.width * 0.22, 72), weight: .light))
                        .foregroundStyle(.white.opacity(0.18))
                        .position(x: geo.size.width * 0.55, y: geo.size.height * 0.72)

                    Image(systemName: "flame.fill")
                        .font(.system(size: min(geo.size.width * 0.2, 64), weight: .regular))
                        .foregroundStyle(.orange.opacity(0.35))
                        .position(x: geo.size.width * 0.18, y: geo.size.height * 0.28)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline.weight(.medium))
                    .opacity(0.92)
                Text(heroSubtitle)
                    .font(.footnote)
                    .lineLimit(3)
                    .opacity(0.88)
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(height: 212)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.35), radius: 20, y: 10)
        .shadow(color: Color.black.opacity(0.45), radius: 28, y: 14)
    }

    private var inspirationalStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Moods")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mosaicSlides) { slide in
                        mosaicTile(slide)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func mosaicTile(_ slide: MosaicSlide) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: slide.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: slide.icon)
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.35))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
            Text(slide.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .padding(14)
        }
        .frame(width: 132, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.32), radius: 12, x: 0, y: 6)
        .shadow(color: Color.appPrimary.opacity(0.1), radius: 16, x: 0, y: 2)
    }

    private var streakCard: some View {
        HomeWidgetCard(
            title: "Streak",
            headline: "\(store.streakDays) days",
            caption: store.streakDays > 0 ? "Don't break the chain" : "Log activity to start",
            icon: "flame.fill",
            gradient: [Color.orange.opacity(0.95), Color.red.opacity(0.6)]
        ) {
            selectedTab = .train
        }
    }

    private var weeklyGoalCard: some View {
        let goal = store.weeklyGoalMinutes
        let done = store.minutesLoggedThisCalendarWeek()
        let frac = store.weeklyGoalProgressFraction()
        return HomeWidgetCard(
            title: "Weekly goal",
            headline: goal > 0 ? "\(done) / \(goal) min" : "Set a goal",
            caption: goal > 0 ? "\(Int(min(frac, 1) * 100))% of this week" : "Open Settings to enable",
            icon: "chart.bar.fill",
            gradient: [Color.mint.opacity(0.9), Color.teal.opacity(0.65)],
            accessory: { HomeMiniRing(fraction: goal > 0 ? frac : 0) },
            action: {
                if goal > 0 {
                    selectedTab = .train
                } else {
                    selectedTab = .settings
                }
            }
        )
    }

    private var timerQuickCard: some View {
        HomeWidgetCard(
            title: "Interval timer",
            headline: "\(store.roundsCount)×\(store.workDurationSec)s",
            caption: "Start a session now",
            icon: "timer",
            gradient: [Color.appPrimary.opacity(0.95), Color.purple.opacity(0.65)]
        ) {
            selectedTab = .timer
        }
    }

    private var trainCard: some View {
        HomeWidgetCard(
            title: "Next routine",
            headline: nextRoutineName,
            caption: "\(store.routines.count) routines saved",
            icon: "figure.strengthtraining.traditional",
            gradient: [Color.purple.opacity(0.85), Color.appAccent.opacity(0.75)]
        ) {
            selectedTab = .train
        }
    }

    private var statsCard: some View {
        HomeWidgetCard(
            title: "All-time",
            headline: "\(store.totalWorkoutMinutes) min",
            caption: "\(store.sessionsCompleted) sessions",
            icon: "heart.text.square.fill",
            gradient: [Color.pink.opacity(0.75), Color.appPrimary.opacity(0.7)]
        ) {
            selectedTab = .train
        }
    }

    private var achievementsCard: some View {
        HomeWidgetCard(
            title: "Achievements",
            headline: "\(unlockedAchievements)/\(AchievementCatalog.all.count)",
            caption: "Track milestones",
            icon: "trophy.fill",
            gradient: [Color.yellow.opacity(0.85), Color.orange.opacity(0.55)]
        ) {
            selectedTab = .achievements
        }
    }

    private var presetsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.customTimerPresets) { preset in
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(Color.appAccent)
                        Text(preset.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                        Text("\(preset.workDurationSec)/\(preset.restDurationSec)s · \(preset.roundsCount) rounds")
                            .font(.caption2)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(14)
                    .frame(width: 158, alignment: .leading)
                    .fitSpherePanel(cornerRadius: 18, elevated: false)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var tipCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appPrimary.opacity(0.55),
                                Color.appAccent.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, y: 4)
                Image(systemName: "lightbulb.max.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appAccent)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text("Balance intensity")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text("Pair your interval timer with a routine on the Train tab for structure and variety.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .fitSpherePanel(cornerRadius: 20)
    }
}

// MARK: - Widget tile

private struct HomeWidgetCard<Accessory: View>: View {
    let title: String
    let headline: String
    let caption: String
    let icon: String
    let gradient: [Color]
    @ViewBuilder var accessory: () -> Accessory
    let action: () -> Void

    init(
        title: String,
        headline: String,
        caption: String,
        icon: String,
        gradient: [Color],
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
        action: @escaping () -> Void
    ) {
        self.title = title
        self.headline = headline
        self.caption = caption
        self.icon = icon
        self.gradient = gradient
        self.accessory = accessory
        self.action = action
    }

    var body: some View {
        Button {
            HapticSound.tapLight()
            action()
        } label: {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: icon)
                    .font(.system(size: 46, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.28))
                    .padding(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(headline)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                    accessory()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(14)
            }
            .frame(maxWidth: .infinity, minHeight: 142)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.38), radius: 16, x: 0, y: 10)
            .shadow(color: Color.appAccent.opacity(0.14), radius: 22, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeMiniRing: View {
    let fraction: Double

    var body: some View {
        let clamped = min(max(fraction.isFinite ? fraction : 0, 0), 1)
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.35), lineWidth: 3)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 36, height: 36)
    }
}
