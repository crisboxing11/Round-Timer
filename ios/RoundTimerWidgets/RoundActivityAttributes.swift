import ActivityKit
import Foundation

/// Shared between the app target and the widget extension.
/// The countdown renders natively from `endsAt` — the app only pushes
/// updates at phase boundaries and pause/resume.
struct RoundActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// "prep" | "work" | "rest" | "done"
        var phase: String
        var round: Int
        /// Wall-clock end of the current phase; ignored while paused.
        var endsAt: Date
        var paused: Bool
        /// Seconds remaining, shown statically while paused.
        var pausedRemaining: Int
    }

    var totalRounds: Int
    var sportName: String
}
