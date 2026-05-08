import Combine
import Foundation

@MainActor
final class Feature1ViewModel: ObservableObject {
    enum ActivePhase: Equatable {
        case work(round: Int)
        case rest(afterRound: Int)
    }

    enum RunState: Equatable {
        case idle
        case running(phase: ActivePhase, endsAt: Date)
        case paused(phase: ActivePhase, remaining: Int)
    }

    @Published private(set) var runState: RunState = .idle

    var isIdle: Bool {
        if case .idle = runState { return true }
        return false
    }

    func start(work: Int, rest: Int, rounds: Int, now: Date = Date()) {
        guard rounds >= 1, work >= 1 else { return }
        let endsAt = now.addingTimeInterval(TimeInterval(work))
        runState = .running(phase: .work(round: 1), endsAt: endsAt)
    }

    func pause(now: Date = Date()) {
        guard case let .running(phase, endsAt) = runState else { return }
        let remaining = max(0, Int(ceil(endsAt.timeIntervalSince(now))))
        runState = .paused(phase: phase, remaining: remaining)
    }

    func resume(now: Date = Date()) {
        guard case let .paused(phase, remaining) = runState else { return }
        let endsAt = now.addingTimeInterval(TimeInterval(remaining))
        runState = .running(phase: phase, endsAt: endsAt)
    }

    func stop() {
        runState = .idle
    }

    /// Call from `TimelineView` while the scene is active.
    func tick(
        now: Date,
        work: Int,
        rest: Int,
        rounds: Int,
        onCompletedSession: () -> Void
    ) {
        guard case let .running(phase, endsAt) = runState else { return }
        let remaining = endsAt.timeIntervalSince(now)
        if remaining > 0 { return }

        switch phase {
        case .work(let roundIndex):
            if roundIndex >= rounds {
                runState = .idle
                onCompletedSession()
                return
            }

            if rest > 0 {
                let ends = now.addingTimeInterval(TimeInterval(rest))
                runState = .running(phase: .rest(afterRound: roundIndex), endsAt: ends)
            } else {
                let ends = now.addingTimeInterval(TimeInterval(work))
                runState = .running(phase: .work(round: roundIndex + 1), endsAt: ends)
            }

        case .rest(let afterRound):
            let ends = now.addingTimeInterval(TimeInterval(work))
            runState = .running(phase: .work(round: afterRound + 1), endsAt: ends)
        }
    }

    func label(for state: RunState) -> String {
        switch state {
        case .idle:
            return "Ready"
        case .paused(let phase, _), .running(let phase, _):
            switch phase {
            case .work:
                return "Work"
            case .rest:
                return "Rest"
            }
        }
    }

    func roundDisplay(for state: RunState, rounds: Int) -> (current: Int, total: Int) {
        switch state {
        case .idle:
            return (1, max(1, rounds))
        case .paused(let phase, _), .running(let phase, _):
            switch phase {
            case .work(let r):
                return (min(r, rounds), rounds)
            case .rest(let afterRound):
                return (min(afterRound, rounds), rounds)
            }
        }
    }

    func remainingSeconds(for state: RunState, now: Date) -> Int? {
        switch state {
        case .idle:
            return nil
        case .paused(_, let remaining):
            return max(0, remaining)
        case .running(_, let endsAt):
            return max(0, Int(ceil(endsAt.timeIntervalSince(now))))
        }
    }
}
