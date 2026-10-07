import ActivityKit
import Foundation

struct DailyGoalLiveActivityPayload {
  let title: String
  let dateLabel: String
  let summaryText: String
  let statusText: String
  let completedCount: Int
  let totalCount: Int
  let skippedCount: Int
  let pendingCount: Int
  let progress: Double
  let requiredTotalCount: Int
  let requiredCompletedCount: Int
  let requiredPendingCount: Int
  let requiredSkippedCount: Int
  let optionalPendingCount: Int
  let requiredPendingTitles: [String]
  let optionalPendingTitles: [String]
  let completedTitles: [String]

  init?(arguments: Any?) {
    guard
      let map = arguments as? [String: Any],
      let title = map["title"] as? String,
      let dateLabel = map["dateLabel"] as? String,
      let summaryText = map["summaryText"] as? String,
      let statusText = map["statusText"] as? String,
      let completedCount = map["completedCount"] as? Int,
      let totalCount = map["totalCount"] as? Int,
      let skippedCount = map["skippedCount"] as? Int,
      let pendingCount = map["pendingCount"] as? Int,
      let progress = map["progress"] as? Double
    else {
      return nil
    }

    self.title = title
    self.dateLabel = dateLabel
    self.summaryText = summaryText
    self.statusText = statusText
    self.completedCount = completedCount
    self.totalCount = totalCount
    self.skippedCount = skippedCount
    self.pendingCount = pendingCount
    self.progress = progress
    self.requiredTotalCount = map["requiredTotalCount"] as? Int ?? totalCount
    self.requiredCompletedCount = map["requiredCompletedCount"] as? Int ?? completedCount
    self.requiredPendingCount = map["requiredPendingCount"] as? Int ?? pendingCount
    self.requiredSkippedCount = map["requiredSkippedCount"] as? Int ?? skippedCount
    self.optionalPendingCount = map["optionalPendingCount"] as? Int ?? 0
    self.requiredPendingTitles = Self.previewTitles(map["requiredPendingTitles"])
    self.optionalPendingTitles = Self.previewTitles(map["optionalPendingTitles"])
    self.completedTitles = Self.previewTitles(map["completedTitles"])
  }

  private static func previewTitles(_ value: Any?) -> [String] {
    (value as? [String] ?? []).prefix(2).map { String($0.prefix(40)) }
  }
}

@available(iOS 16.1, *)
final class DailyGoalLiveActivityManager {
  static let shared = DailyGoalLiveActivityManager()

  private init() {}

  func sync(_ payload: DailyGoalLiveActivityPayload) async throws {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      return
    }

    let state = makeContentState(from: payload)

    if let activity = Activity<DailyGoalAttributes>.activities.first {
      if #available(iOS 16.2, *) {
        await activity.update(makeContent(state: state))
      } else {
        await activity.update(using: state)
      }
      return
    }

    let attributes = DailyGoalAttributes(title: payload.title)
    if #available(iOS 16.2, *) {
      _ = try Activity.request(
        attributes: attributes,
        content: makeContent(state: state),
        pushType: nil
      )
    } else {
      _ = try Activity.request(
        attributes: attributes,
        contentState: state,
        pushType: nil
      )
    }
  }

  func endAll() async {
    for activity in Activity<DailyGoalAttributes>.activities {
      if #available(iOS 16.2, *) {
        await activity.end(nil, dismissalPolicy: .immediate)
      } else {
        await activity.end(using: nil, dismissalPolicy: .immediate)
      }
    }
  }

  private func makeContentState(
    from payload: DailyGoalLiveActivityPayload
  ) -> DailyGoalAttributes.ContentState {
    DailyGoalAttributes.ContentState(
      dateLabel: payload.dateLabel,
      summaryText: payload.summaryText,
      statusText: payload.statusText,
      completedCount: payload.completedCount,
      totalCount: payload.totalCount,
      skippedCount: payload.skippedCount,
      pendingCount: payload.pendingCount,
      progress: min(max(payload.progress, 0), 1),
      requiredTotalCount: payload.requiredTotalCount,
      requiredCompletedCount: payload.requiredCompletedCount,
      requiredPendingCount: payload.requiredPendingCount,
      requiredSkippedCount: payload.requiredSkippedCount,
      optionalPendingCount: payload.optionalPendingCount,
      requiredPendingTitles: payload.requiredPendingTitles,
      optionalPendingTitles: payload.optionalPendingTitles,
      completedTitles: payload.completedTitles
    )
  }

  @available(iOS 16.2, *)
  private func makeContent(
    state: DailyGoalAttributes.ContentState
  ) -> ActivityContent<DailyGoalAttributes.ContentState> {
    ActivityContent(
      state: state,
      staleDate: staleDate(),
      relevanceScore: 100
    )
  }

  @available(iOS 16.2, *)
  private func staleDate() -> Date {
    let now = Date()
    let oneHourAhead = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
    let endOfDay = Calendar.current.date(
      bySettingHour: 23,
      minute: 59,
      second: 59,
      of: now
    ) ?? oneHourAhead
    return min(oneHourAhead, endOfDay)
  }
}
