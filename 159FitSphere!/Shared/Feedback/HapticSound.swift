import AudioToolbox
import Combine
import UIKit

enum HapticSound {
    static func tapLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func impactMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func successNotification() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warningNotification() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func playSystemSound(_ id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
