import ActivityKit
import SwiftUI
import WidgetKit

// The gym LED palette, mirrored from lib/theme/led_theme.dart.
private extension Color {
    static let ledBg = Color(red: 0.039, green: 0.043, blue: 0.039)
    static let ledAmber = Color(red: 1.0, green: 0.702, blue: 0.141)
    static let ledGreen = Color(red: 0.239, green: 0.949, blue: 0.357)
    static let ledRed = Color(red: 1.0, green: 0.231, blue: 0.231)
    static let ledDim = Color(red: 0.541, green: 0.569, blue: 0.541)
}

private func phaseColor(_ phase: String) -> Color {
    switch phase {
    case "work": return .ledGreen
    case "rest": return .ledRed
    case "done": return .ledGreen
    default: return .ledAmber
    }
}

private func stateLabel(_ state: RoundActivityAttributes.ContentState) -> String {
    if state.paused { return "PAUSED" }
    switch state.phase {
    case "work": return "FIGHT"
    case "rest": return "REST"
    case "done": return "DONE"
    default: return "GET READY"
    }
}

private func roundLabel(
    _ state: RoundActivityAttributes.ContentState, total: Int
) -> String {
    switch state.phase {
    case "prep": return "GET READY"
    case "done": return "TIME"
    default: return "ROUND \(state.round) OF \(total)"
    }
}

private func fmt(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}

/// The ticking countdown, or a static value when paused/done.
/// The timer text needs an explicit width and scale allowance, or the
/// system squeezes it and renders digits as dashes.
private struct Countdown: View {
    let state: RoundActivityAttributes.ContentState
    var font: Font
    var width: CGFloat

    var body: some View {
        Group {
            if state.phase == "done" {
                Text("0:00")
            } else if state.paused {
                Text(fmt(state.pausedRemaining))
            } else if state.endsAt > Date.now {
                Text(timerInterval: Date.now...state.endsAt, countsDown: true)
            } else {
                Text("0:00")
            }
        }
        .font(font)
        .fontWeight(.heavy)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundStyle(state.paused ? Color.ledDim : phaseColor(state.phase))
        .frame(width: width, alignment: .trailing)
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<RoundActivityAttributes>

    var body: some View {
        let state = context.state
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(roundLabel(state, total: context.attributes.totalRounds))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .kerning(2)
                    .foregroundStyle(Color.ledDim)
                Text(stateLabel(state))
                    .font(.title2)
                    .fontWeight(.heavy)
                    .kerning(3)
                    .foregroundStyle(
                        state.paused ? Color.ledDim : phaseColor(state.phase))
            }
            Spacer()
            Countdown(state: state, font: .system(size: 44), width: 140)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color.ledBg)
        .activitySystemActionForegroundColor(Color.ledDim)
    }
}

struct RoundTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoundActivityAttributes.self) { context in
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(roundLabel(state, total: context.attributes.totalRounds))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .kerning(1.5)
                            .foregroundStyle(Color.ledDim)
                        Text(stateLabel(state))
                            .font(.headline)
                            .fontWeight(.heavy)
                            .kerning(2)
                            .foregroundStyle(
                                state.paused
                                    ? Color.ledDim : phaseColor(state.phase))
                    }
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(state: state, font: .system(size: 32), width: 104)
                        .padding(.trailing, 6)
                }
            } compactLeading: {
                Circle()
                    .fill(state.paused ? Color.ledDim : phaseColor(state.phase))
                    .frame(width: 10, height: 10)
            } compactTrailing: {
                Countdown(state: state, font: .system(size: 15), width: 44)
            } minimal: {
                Circle()
                    .fill(state.paused ? Color.ledDim : phaseColor(state.phase))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

@main
struct RoundTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoundTimerLiveActivity()
    }
}
