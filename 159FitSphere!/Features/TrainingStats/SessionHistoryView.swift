import SwiftUI

struct SessionHistoryView: View {
    @EnvironmentObject private var store: AppDataStore

    private static let completedDF: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private var sortedEntries: [SessionHistoryEntry] {
        store.sessionHistory.sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        Group {
            if sortedEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color.appAccent)

                    Text("No completed sessions yet.")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
                .fitSpherePanel(cornerRadius: 20)
                .padding(.horizontal, 16)
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(Self.completedDF.string(from: entry.completedAt))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                Spacer(minLength: 8)
                                Text(entry.source.displayTitle)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.appSurface.opacity(0.85),
                                                        Color.appBackground.opacity(0.65)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.appAccent.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            HStack(spacing: 8) {
                                Text("\(entry.durationMinutes) min")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appPrimary)
                                    .monospacedDigit()

                                if let name = entry.routineName, name.isEmpty == false {
                                    Text("· \(name)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(12)
                        .fitSpherePanel(cornerRadius: 14, elevated: false)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppChromeBackground())
        .navigationTitle("Session history")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.appPrimary)
    }
}
