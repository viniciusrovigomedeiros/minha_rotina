import ActivityKit

@available(iOS 16.1, *)
struct DailyGoalAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var dateLabel: String
    var summaryText: String
    var statusText: String
    var completedCount: Int
    var totalCount: Int
    var skippedCount: Int
    var pendingCount: Int
    var progress: Double
    // Optional fields also decode Live Activities created before this update.
    var requiredTotalCount: Int? = nil
    var requiredCompletedCount: Int? = nil
    var requiredPendingCount: Int? = nil
    var requiredSkippedCount: Int? = nil
    var optionalPendingCount: Int? = nil
    var requiredPendingTitles: [String]? = nil
    var optionalPendingTitles: [String]? = nil
    var completedTitles: [String]? = nil

    var requiredTotal: Int { requiredTotalCount ?? totalCount }
    var requiredCompleted: Int { requiredCompletedCount ?? completedCount }
    var requiredPending: Int { requiredPendingCount ?? pendingCount }
    var requiredSkipped: Int { requiredSkippedCount ?? skippedCount }
    var optionalPending: Int { optionalPendingCount ?? 0 }
    var requiredProgress: Double {
      requiredTotal == 0 ? 0 : min(max(Double(requiredCompleted) / Double(requiredTotal), 0), 1)
    }
    var focusLabel: String {
      if requiredTotal == 0 { return "Sem obrigatórias hoje" }
      if requiredPending == 0 && requiredSkipped == 0 { return "Obrigatórias feitas" }
      if requiredPending == 0 { return requiredSkipped == 1 ? "1 obrigatória pulada" : "\(requiredSkipped) obrigatórias puladas" }
      return "\(requiredCompleted)/\(requiredTotal) obrigatórias"
    }
  }

  var title: String
}
