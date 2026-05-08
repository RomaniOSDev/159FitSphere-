//
//  ContentView.swift
//  159FitSphere!
//
//  Created by Roman on 5/8/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @StateObject private var achievementBanner = AchievementBannerQueue()

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if store.hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)

            VStack(spacing: 8) {
                if let title = achievementBanner.visibleTitle {
                    AchievementBannerView(title: title)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let hint = store.softHintMessage, hint.isEmpty == false {
                    SoftHintBannerView(message: hint)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 12)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: achievementBanner.visibleTitle)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: store.softHintMessage)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                store.sceneBecameActive()
            case .inactive, .background:
                store.sceneResignedActive()
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            guard let id = notification.object as? String else { return }
            achievementBanner.enqueue(achievementId: id)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
