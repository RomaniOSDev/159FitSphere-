import SwiftUI
import StoreKit
import UIKit
import UniformTypeIdentifiers

private enum StatsReportPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Last 7 days"
        case .month: return "Last 30 days"
        case .all: return "All time"
        }
    }

    func range(reference: Date = Date(), calendar: Calendar = .current) -> (start: Date, end: Date) {
        let end = reference
        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
            return (start, end)
        case .month:
            let start = calendar.date(byAdding: .day, value: -30, to: end) ?? end
            return (start, end)
        case .all:
            return (Date.distantPast, end)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var showResetConfirm = false
    @State private var showExportJSON = false
    @State private var exportBackupDocument: FitSphereJSONBackupDocument?
    @State private var showImportJSON = false
    @State private var importAlertMessage: String?
    @State private var reportPeriod: StatsReportPeriod = .month
    @State private var showExportPDF = false
    @State private var exportPDFDocument: FitSpherePDFReportDocument?
    @State private var showExportText = false
    @State private var exportTextDocument: FitSphereTextReportDocument?
    @State private var activityShareItems: [Any] = []
    @State private var showActivityShare = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    statsCard
                    weeklyGoalCard
                    backupCard
                    reportsCard

                    settingsRow(title: "Privacy Policy", isDestructive: false) {
                        openPrivacyPolicy()
                    }

                    settingsRow(title: "Rate App", isDestructive: false) {
                        rateApp()
                    }

                    settingsRow(title: "Support", isDestructive: false) {
                        openSupportEmail()
                    }

                    settingsRow(title: "Reset All Data", isDestructive: true) {
                        showResetConfirm = true
                    }

                    Text(versionText)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
            .fileExporter(
                isPresented: $showExportJSON,
                document: exportBackupDocument,
                contentType: .json,
                defaultFilename: "FitSphere-backup"
            ) { _ in
                exportBackupDocument = nil
            }
            .fileExporter(
                isPresented: $showExportPDF,
                document: exportPDFDocument,
                contentType: .pdf,
                defaultFilename: "FitSphere-report"
            ) { _ in
                exportPDFDocument = nil
            }
            .fileExporter(
                isPresented: $showExportText,
                document: exportTextDocument,
                contentType: .plainText,
                defaultFilename: "FitSphere-report"
            ) { _ in
                exportTextDocument = nil
            }
            .fileImporter(
                isPresented: $showImportJSON,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let needsAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if needsAccess {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    do {
                        let data = try Data(contentsOf: url)
                        try store.importBackup(data: data)
                        importAlertMessage = "Backup imported successfully."
                    } catch {
                        importAlertMessage = error.localizedDescription
                    }
                case .failure(let error):
                    importAlertMessage = error.localizedDescription
                }
            }
            .alert("Notice", isPresented: Binding(
                get: { importAlertMessage != nil },
                set: { if !$0 { importAlertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    importAlertMessage = nil
                }
            } message: {
                Text(importAlertMessage ?? "")
            }
            .sheet(isPresented: $showActivityShare) {
                ActivityShareSheet(items: activityShareItems)
            }
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {
                    HapticSound.tapLight()
                }
                Button("Reset", role: .destructive) {
                    HapticSound.warningNotification()
                    store.resetAllData()
                }
            } message: {
                Text("This removes all saved workouts, routines, timers, stats, and achievements from this device.")
            }
        }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            metricRow(title: "Routines saved", value: "\(store.routines.count)")
            metricRow(title: "Sessions completed", value: "\(store.sessionsCompleted)")
            metricRow(title: "Total workout minutes", value: "\(store.totalWorkoutMinutes)")
            metricRow(title: "Current streak (days)", value: "\(store.streakDays)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var weeklyGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly goal (minutes)")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Text(
                store.weeklyGoalMinutes == 0
                    ? "Goal is off — the stats tab still shows totals."
                    : "Aim for \(store.weeklyGoalMinutes) minutes this week (Mon–Sun, simple progress bar only)."
            )
            .font(.subheadline)
            .foregroundStyle(Color.appTextSecondary)

            Slider(
                value: Binding(
                    get: { Double(store.weeklyGoalMinutes) },
                    set: { store.setWeeklyGoalMinutes(Int($0.rounded())) }
                ),
                in: 0...600,
                step: 15
            )
            .tint(Color.appAccent)

            HStack {
                Text("0 off")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("\(store.weeklyGoalMinutes) min")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .monospacedDigit()
                Spacer()
                Text("600")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup (JSON)")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Text("Export or import a single file — stays on device (Files, AirDrop, no cloud required).")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Button {
                    HapticSound.tapLight()
                    do {
                        let data = try store.exportBackup()
                        exportBackupDocument = FitSphereJSONBackupDocument(data: data)
                        showExportJSON = true
                    } catch {
                        importAlertMessage = error.localizedDescription
                    }
                } label: {
                    Text("Export")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .fitSpherePrimaryButton(cornerRadius: 14)
                }
                .buttonStyle(.plain)

                Button {
                    HapticSound.tapLight()
                    showImportJSON = true
                } label: {
                    Text("Import")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .fitSphereInsetPanel(cornerRadius: 14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private var reportsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen-ready report")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            Text("Share a PDF or plain-text summary for the selected period (built locally).")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)

            Picker("Period", selection: $reportPeriod) {
                ForEach(StatsReportPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)

            Button {
                HapticSound.tapLight()
                let payload = reportPayload()
                let pdf = StatsPDFExporter.makeReportPDF(
                    sessions: payload.sessions,
                    periodLabel: payload.label,
                    totalMinutes: payload.totalMinutes,
                    sessionsCount: payload.sessions.count,
                    streakDays: store.streakDays
                )
                exportPDFDocument = FitSpherePDFReportDocument(data: pdf)
                showExportPDF = true
            } label: {
                Text("Save / share PDF…")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .fitSpherePrimaryButton(cornerRadius: 14)
            }
            .buttonStyle(.plain)

            Button {
                HapticSound.tapLight()
                let payload = reportPayload()
                let text = StatsPDFExporter.makeReportPlainText(
                    sessions: payload.sessions,
                    periodLabel: payload.label,
                    totalMinutes: payload.totalMinutes,
                    sessionsCount: payload.sessions.count,
                    streakDays: store.streakDays
                )
                exportTextDocument = FitSphereTextReportDocument(text: text)
                showExportText = true
            } label: {
                Text("Save text file…")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .fitSphereInsetPanel(cornerRadius: 14)
            }
            .buttonStyle(.plain)

            Button {
                HapticSound.tapLight()
                let payload = reportPayload()
                let text = StatsPDFExporter.makeReportPlainText(
                    sessions: payload.sessions,
                    periodLabel: payload.label,
                    totalMinutes: payload.totalMinutes,
                    sessionsCount: payload.sessions.count,
                    streakDays: store.streakDays
                )
                activityShareItems = [text]
                showActivityShare = true
            } label: {
                Text("Share text…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private func reportPayload() -> (sessions: [SessionHistoryEntry], label: String, totalMinutes: Int) {
        let range = reportPeriod.range()
        let cal = Calendar.current
        let startOfEndDay = cal.startOfDay(for: range.end)
        let end = cal.date(byAdding: .day, value: 1, to: startOfEndDay) ?? range.end

        let sessions = store.sessionHistory.filter { entry in
            entry.completedAt >= range.start && entry.completedAt < end
        }
        let total = sessions.reduce(0) { $0 + $1.durationMinutes }
        let label = "\(reportPeriod.title) — through \(Self.mediumDate.string(from: range.end))"
        return (sessions, label, total)
    }

    private static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

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

    private func settingsRow(title: String, isDestructive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticSound.tapLight()
            action()
        } label: {
            HStack {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.appPrimary : Color.appTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.55))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .fitSpherePanel(cornerRadius: 16, elevated: false)
        }
        .buttonStyle(SettingsPressStyle())
    }

    private func openPrivacyPolicy() {
        if let url = AppExternalLink.privacyPolicy.url {
            UIApplication.shared.open(url)
        }
    }

    private func openSupportEmail() {
        if let url = AppExternalLink.supportEmail.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct SettingsPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}
