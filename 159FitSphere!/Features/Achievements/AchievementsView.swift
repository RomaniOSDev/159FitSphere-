import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var unlockedCount: Int {
        AchievementCatalog.all.filter { $0.isUnlocked(store: store) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AchievementCatalog.all) { item in
                            let unlocked = item.isUnlocked(store: store)
                            achievementCell(item, unlocked: unlocked)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            metricRow(title: "Unlocked", value: "\(unlockedCount) / \(AchievementCatalog.all.count)")
            metricRow(title: "Workouts completed", value: "\(store.workoutsCompleted)")
            metricRow(title: "Total workout minutes", value: "\(store.totalWorkoutMinutes)")
            metricRow(title: "Current streak (days)", value: "\(store.streakDays)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appTextPrimary)
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func achievementCell(_ item: AchievementDefinition, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: unlocked ? "star.circle.fill" : "star.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary.opacity(0.55))

                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            Text(item.description)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16, elevated: unlocked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(unlocked ? "Unlocked" : "Locked"). \(item.description)")
    }
}
