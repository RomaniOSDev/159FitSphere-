import AudioToolbox
import SwiftUI

struct Feature3View: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var selectedDayIndex: Int?
    @State private var selectedWeekIndex: Int?
    @State private var refreshAnimToken: Int = 0

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var hasAnyData: Bool {
        store.sessionsCompleted > 0
            || store.totalWorkoutMinutes > 0
            || store.weeklyMinutes.contains(where: { $0 > 0 })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    weeklyGoalCard

                    fourWeeksChartCard

                    if hasAnyData {
                        chartCard
                        summaryCard
                    } else {
                        emptyState
                    }

                    Button {
                        refreshTapped()
                    } label: {
                        Text("Refresh Data")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .fitSpherePrimaryButton(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(1.0 + (CGFloat(refreshAnimToken % 3) * 0.012))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Training Stats")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SessionHistoryView()
                    } label: {
                        Text("History")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private var weeklyGoalCard: some View {
        let goal = store.weeklyGoalMinutes
        let logged = store.minutesLoggedThisCalendarWeek()
        let fraction = store.weeklyGoalProgressFraction()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Weekly minute goal")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            if goal <= 0 {
                Text("Turn on a goal in Settings to track this week in one place.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                ProgressView(value: min(max(fraction, 0), 1), total: 1)
                    .progressViewStyle(.linear)
                    .tint(Color.appAccent)

                Text("\(logged) of \(goal) minutes this week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var fourWeeksChartCard: some View {
        let data = store.lastFourWeeksChartData()
        let maxVal = max(data.map(\.minutes).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Minutes by week (last 4)")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            if data.isEmpty {
                Text("Complete a session to see your monthly trend.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let chartTopPadding: CGFloat = 10
                    let chartBottomLabels: CGFloat = 26
                    let chartAreaHeight = height - chartTopPadding - chartBottomLabels
                    let barSpacing: CGFloat = 10
                    let count = data.count
                    let barWidth = (width - barSpacing * CGFloat(count - 1)) / CGFloat(count)

                    ZStack(alignment: .bottom) {
                        Canvas { context, size in
                            for i in 0..<data.count {
                                let value = data[i].minutes
                                let barHeight = CGFloat(value) / CGFloat(maxVal) * chartAreaHeight
                                let x = CGFloat(i) * (barWidth + barSpacing)
                                let y = chartTopPadding + (chartAreaHeight - max(6, barHeight))
                                let rect = CGRect(x: x, y: y, width: barWidth, height: max(6, barHeight))
                                let path = Path(roundedRect: rect, cornerRadius: 6)
                                let color = (selectedWeekIndex == i) ? Color.appAccent : Color.appPrimary.opacity(0.55)
                                context.fill(path, with: .color(color))
                            }
                        }
                        .frame(width: width, height: height)
                        .animation(.easeInOut(duration: 0.25), value: selectedWeekIndex)

                        HStack(alignment: .bottom, spacing: barSpacing) {
                            ForEach(0..<data.count, id: \.self) { index in
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: height - chartBottomLabels)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        HapticSound.tapLight()
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            selectedWeekIndex = index
                                        }
                                    }
                            }
                        }
                    }
                }
                .frame(height: 200)

                HStack(spacing: 0) {
                    ForEach(0..<data.count, id: \.self) { index in
                        Text(data[index].label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                if let i = selectedWeekIndex, i < data.count {
                    Text("Week of \(data[i].label): \(data[i].minutes) minutes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                } else {
                    Text("Tap a bar for weekly totals.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(16)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minutes per day")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let data = store.weeklyMinutes
                let maxVal = max(data.max() ?? 0, 1)

                ZStack(alignment: .bottom) {
                    Canvas { context, size in
                        let chartTopPadding: CGFloat = 10
                        let chartBottomLabels: CGFloat = 26
                        let chartAreaHeight = size.height - chartTopPadding - chartBottomLabels
                        let barSpacing: CGFloat = 8
                        let barWidth = (size.width - barSpacing * 6) / 7

                        for i in 0..<7 {
                            let value = data[i]
                            let barHeight = CGFloat(value) / CGFloat(maxVal) * chartAreaHeight
                            let x = CGFloat(i) * (barWidth + barSpacing)
                            let y = chartTopPadding + (chartAreaHeight - max(6, barHeight))
                            let rect = CGRect(x: x, y: y, width: barWidth, height: max(6, barHeight))
                            let path = Path(roundedRect: rect, cornerRadius: 6)
                            let color = (selectedDayIndex == i) ? Color.appAccent : Color.appPrimary.opacity(0.55)
                            context.fill(path, with: .color(color))
                        }
                    }
                    .frame(width: width, height: height)
                    .animation(.easeInOut(duration: 0.28), value: data)
                    .animation(.easeInOut(duration: 0.25), value: selectedDayIndex)

                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: height - 26)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticSound.tapLight()
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedDayIndex = index
                                    }
                                }
                        }
                    }
                }
            }
            .frame(height: 230)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayLabels[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            if let selectedDayIndex {
                Text("\(dayLabels[selectedDayIndex]): \(store.weeklyMinutes[selectedDayIndex]) minutes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                Text("Tap a bar to see exact minutes.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            metricRow(title: "Sessions Completed", value: "\(store.sessionsCompleted)")
            metricRow(title: "Total Minutes", value: "\(store.totalWorkoutMinutes)")
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.wave.circle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.appAccent)

            Text("No workout data yet - Start your first session!")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .fitSpherePanel(cornerRadius: 18)
    }

    private func refreshTapped() {
        HapticSound.impactLight()
        AudioServicesPlaySystemSound(1103)
        withAnimation(.easeInOut(duration: 0.3)) {
            refreshAnimToken &+= 1
            store.refreshWeeklyDisplayFromStore()
        }
    }
}
