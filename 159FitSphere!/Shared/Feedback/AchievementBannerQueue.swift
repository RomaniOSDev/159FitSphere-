import Combine
import SwiftUI

@MainActor
final class AchievementBannerQueue: ObservableObject {
    @Published private(set) var visibleTitle: String?

    private var pendingTitles: [String] = []
    private var isDraining = false

    func enqueue(achievementId: String) {
        let title = AchievementCatalog.all.first { $0.id == achievementId }?.title ?? "Achievement"
        pendingTitles.append(title)
        drainIfNeeded()
    }

    private func drainIfNeeded() {
        guard isDraining == false else { return }
        isDraining = true

        Task {
            await drain()
            await MainActor.run {
                isDraining = false
                if pendingTitles.isEmpty == false {
                    drainIfNeeded()
                }
            }
        }
    }

    private func drain() async {
        while true {
            let title: String? = await MainActor.run {
                if pendingTitles.isEmpty { return nil }
                return pendingTitles.removeFirst()
            }

            guard let title else { return }

            await MainActor.run {
                HapticSound.successNotification()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    visibleTitle = title
                }
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.28)) {
                    visibleTitle = nil
                }
            }

            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}
