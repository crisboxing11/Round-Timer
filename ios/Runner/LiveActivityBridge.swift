import ActivityKit
import Flutter
import Foundation

/// Method-channel bridge for the round Live Activity. The Dart side sends
/// full state at phase boundaries and pause/resume; the countdown itself
/// renders natively from `endsAt` with zero per-second traffic.
enum LiveActivityBridge {
    private static let channelName = "round_timer/live_activity"

    static func register(with registry: FlutterPluginRegistry) {
        guard let registrar = registry.registrar(forPlugin: "LiveActivityBridge")
        else { return }
        let channel = FlutterMethodChannel(
            name: channelName, binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler(handle)
    }

    private static func handle(
        _ call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
        guard #available(iOS 16.2, *) else {
            result(false)
            return
        }
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "start":
            start(args: args, result: result)
        case "update":
            Task { await Holder.shared.update(state: contentState(from: args)) }
            result(true)
        case "end":
            Task { await Holder.shared.end() }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @available(iOS 16.2, *)
    private static func start(
        args: [String: Any], result: @escaping FlutterResult
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(false)
            return
        }
        let attributes = RoundActivityAttributes(
            totalRounds: args["totalRounds"] as? Int ?? 0,
            sportName: args["sportName"] as? String ?? "")
        let state = contentState(from: args)
        Task {
            // A stale activity from a crashed session would shadow the new one.
            await Holder.shared.endAll()
            let ok = await Holder.shared.start(attributes: attributes, state: state)
            DispatchQueue.main.async { result(ok) }
        }
    }

    @available(iOS 16.2, *)
    private static func contentState(from args: [String: Any])
        -> RoundActivityAttributes.ContentState
    {
        let endsAtMs = args["endsAtMs"] as? Double
            ?? Double(args["endsAtMs"] as? Int ?? 0)
        return RoundActivityAttributes.ContentState(
            phase: args["phase"] as? String ?? "prep",
            round: args["round"] as? Int ?? 0,
            endsAt: Date(timeIntervalSince1970: endsAtMs / 1000.0),
            paused: args["paused"] as? Bool ?? false,
            pausedRemaining: args["pausedRemaining"] as? Int ?? 0)
    }

    /// Serializes all ActivityKit access on one actor.
    @available(iOS 16.2, *)
    private actor Holder {
        static let shared = Holder()
        private var activity: Activity<RoundActivityAttributes>?

        func start(
            attributes: RoundActivityAttributes,
            state: RoundActivityAttributes.ContentState
        ) -> Bool {
            activity = try? Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil))
            return activity != nil
        }

        func update(state: RoundActivityAttributes.ContentState) async {
            await activity?.update(.init(state: state, staleDate: nil))
        }

        func end() async {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }

        func endAll() async {
            for a in Activity<RoundActivityAttributes>.activities {
                await a.end(nil, dismissalPolicy: .immediate)
            }
            activity = nil
        }
    }
}
