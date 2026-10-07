import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct DailyGoalWidgetBundle: WidgetBundle {
  var body: some Widget {
    DailyGoalWidget()
    OkrReminderWidget()
    if #available(iOS 17.0, *) {
      QuarterCountdownWidget()
    }
  }
}

struct DailyGoalWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: DailyGoalAttributes.self) { context in
      DailyGoalLockScreenView(state: context.state)
        .activityBackgroundTint(DailyGoalStyle.background)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Hoje", systemImage: "sun.max.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DailyGoalStyle.required)
        }

        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.focusLabel)
            .font(.caption.weight(.medium))
            .foregroundStyle(DailyGoalStyle.secondary)
            .lineLimit(1)
        }

        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 8) {
            DailyGoalProgressTrack(state: context.state)
            DailyGoalActivityRows(state: context.state)
          }
          .padding(.top, 2)
        }
      } compactLeading: {
        Image(systemName: "checklist")
          .foregroundStyle(DailyGoalStyle.completed)
      } compactTrailing: {
        Text(context.state.requiredTotal == 0
          ? "+\(context.state.optionalPending)"
          : "\(context.state.requiredCompleted)/\(context.state.requiredTotal)")
          .font(.caption.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(DailyGoalStyle.required)
          .accessibilityLabel(context.state.focusLabel)
      } minimal: {
        Image(systemName: context.state.requiredTotal == 0 && context.state.optionalPending > 0
          ? "plus.circle" : context.state.requiredPending == 0 && context.state.requiredSkipped == 0
          ? "checkmark.circle.fill" : "checklist")
          .foregroundStyle(DailyGoalStyle.required)
      }
      .keylineTint(DailyGoalStyle.required)
    }
  }
}

private enum DailyGoalStyle {
  static let background = Color(red: 0.075, green: 0.09, blue: 0.11)
  static let secondary = Color(red: 0.67, green: 0.71, blue: 0.76)
  static let required = Color(red: 1.0, green: 0.76, blue: 0.42)
  static let optional = Color(red: 0.64, green: 0.75, blue: 0.91)
  static let completed = Color(red: 0.47, green: 0.86, blue: 0.69)
}

private struct DailyGoalLockScreenView: View {
  let state: DailyGoalAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: "sun.max.fill")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(DailyGoalStyle.required)
            .accessibilityHidden(true)
          Text("Hoje")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
        }
        .fixedSize()
        ViewThatFits(in: .horizontal) {
          Text(state.dateLabel)
            .font(.system(size: 11))
            .foregroundStyle(DailyGoalStyle.secondary)
            .fixedSize()
          Color.clear.frame(width: 0, height: 0)
        }
        Spacer(minLength: 4)
        Text(state.focusLabel)
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(DailyGoalStyle.secondary)
          .lineLimit(1)
          .layoutPriority(1)
      }

      DailyGoalProgressTrack(state: state)
      DailyGoalActivityRows(state: state)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .dynamicTypeSize(...DynamicTypeSize.large)
  }
}

private struct DailyGoalProgressTrack: View {
  let state: DailyGoalAttributes.ContentState

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(.white.opacity(0.1))
        Capsule()
          .fill(DailyGoalStyle.completed)
          .frame(width: geometry.size.width * state.requiredProgress)
      }
    }
    .frame(height: 3)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Progresso das obrigatórias")
    .accessibilityValue("\(state.requiredCompleted) de \(state.requiredTotal) feitas")
  }
}

private struct DailyGoalActivityRows: View {
  let state: DailyGoalAttributes.ContentState

  var body: some View {
    VStack(spacing: 5) {
      DailyGoalActivityRow(
        label: "Obrigatórias", symbol: "circle.dashed", color: DailyGoalStyle.required,
        count: state.requiredPending, titles: state.requiredPendingTitles ?? [],
        emptyText: state.requiredSkipped > 0
          ? state.requiredSkipped == 1 ? "1 pulada" : "\(state.requiredSkipped) puladas"
          : state.requiredTotal == 0 ? "Nenhuma hoje" : "Tudo feito"
      )
      DailyGoalActivityRow(
        label: "Opcionais", symbol: "plus.circle", color: DailyGoalStyle.optional,
        count: state.optionalPending, titles: state.optionalPendingTitles ?? [],
        emptyText: "Nenhuma pendente"
      )
      DailyGoalActivityRow(
        label: "Feitas", symbol: "checkmark.circle.fill", color: DailyGoalStyle.completed,
        count: state.completedCount, titles: state.completedTitles ?? [],
        emptyText: "Nenhuma concluída"
      )
    }
  }
}

private struct DailyGoalActivityRow: View {
  let label: String
  let symbol: String
  let color: Color
  let count: Int
  let titles: [String]
  let emptyText: String

  var body: some View {
    HStack(spacing: 8) {
      HStack(spacing: 5) {
        Image(systemName: symbol)
          .font(.system(size: 12, weight: .medium))
          .frame(width: 14)
        Text(label)
          .font(.system(size: 11, weight: .semibold))
      }
      .foregroundStyle(color)
      .frame(width: 98, alignment: .leading)

      Text("\(count)")
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(color)
        .frame(minWidth: 22, minHeight: 22)
        .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 7))
        .fixedSize()

      Text(titles.isEmpty ? (count == 0 ? emptyText : "\(count) atividades")
        : titles.joined(separator: " · "))
        .font(.system(size: 12, weight: count > 0 ? .medium : .regular))
        .foregroundStyle(count > 0 ? .white.opacity(0.92) : DailyGoalStyle.secondary)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)

      if count > titles.count && !titles.isEmpty {
        Text("+\(count - titles.count)")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(DailyGoalStyle.secondary)
          .fixedSize()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(label): \(count). \(titles.isEmpty ? emptyText : titles.joined(separator: ", "))")
  }
}

// Calendar-based countdowns work without an OKR or a saved app snapshot.
private struct QuarterCountdown {
  let quarter: Int
  let year: Int
  let daysRemaining: Int
  let hasEnded: Bool

  init(date: Date, quarter: Int? = nil, year: Int? = nil, timeZone: TimeZone = .current) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let currentYear = calendar.component(.year, from: date)
    self.quarter = quarter.flatMap { (1...4).contains($0) ? $0 : nil }
      ?? (calendar.component(.month, from: date) - 1) / 3 + 1
    self.year = year.flatMap { (1...9998).contains($0) ? $0 : nil } ?? currentYear
    let nextQuarterStart = calendar.date(from: DateComponents(
      year: self.year, month: self.quarter * 3 + 1, day: 1
    ))!
    let end = calendar.date(byAdding: .day, value: -1, to: nextQuarterStart)!
    let remaining = calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: date), to: end
    ).day ?? 0
    self.daysRemaining = max(remaining, 0)
    self.hasEnded = remaining < 0
  }

  var quarterLabel: String { "\(quarter)º tri" }
  var unitLabel: String {
    if hasEnded { return "fim" }
    if daysRemaining == 0 { return "hoje" }
    return daysRemaining == 1 ? "dia" : "dias"
  }
  var accessibilityLabel: String {
    let target = "\(quarter)º trimestre de \(year)"
    if hasEnded { return "\(target) encerrado" }
    if daysRemaining == 0 { return "\(target) termina hoje" }
    return "Faltam \(daysRemaining) \(unitLabel) para o fim do \(target)"
  }
}

@available(iOS 17.0, *)
enum CountdownQuarter: String, AppEnum {
  case current, first, second, third, fourth

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Trimestre")
  static var caseDisplayRepresentations: [CountdownQuarter: DisplayRepresentation] = [
    .current: "Trimestre atual",
    .first: "1º trimestre · jan–mar",
    .second: "2º trimestre · abr–jun",
    .third: "3º trimestre · jul–set",
    .fourth: "4º trimestre · out–dez",
  ]

  var number: Int? {
    switch self {
    case .current: return nil
    case .first: return 1
    case .second: return 2
    case .third: return 3
    case .fourth: return 4
    }
  }
}

@available(iOS 17.0, *)
struct QuarterCountdownIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Fim do trimestre"
  static var description = IntentDescription(
    "Escolha o trimestre. Deixe o ano vazio para acompanhar o ano atual."
  )

  @Parameter(title: "Trimestre", default: .current)
  var quarter: CountdownQuarter

  @Parameter(title: "Ano")
  var year: Int?
}

private struct QuarterCountdownEntry: TimelineEntry {
  let date: Date
  let countdown: QuarterCountdown
}

private func quarterCountdownTimeline(
  now: Date, quarter: Int? = nil, year: Int? = nil
) -> Timeline<QuarterCountdownEntry> {
  var entries = [QuarterCountdownEntry(
    date: now, countdown: QuarterCountdown(date: now, quarter: quarter, year: year)
  )]
  let calendar = Calendar.current
  let today = calendar.startOfDay(for: now)
  for offset in 1...32 {
    guard let midnight = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
    entries.append(QuarterCountdownEntry(
      date: midnight,
      countdown: QuarterCountdown(date: midnight, quarter: quarter, year: year)
    ))
  }
  return Timeline(entries: entries, policy: .atEnd)
}

@available(iOS 17.0, *)
private struct ConfigurableQuarterProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuarterCountdownEntry {
    QuarterCountdownEntry(date: Date(), countdown: QuarterCountdown(date: Date()))
  }

  func snapshot(for configuration: QuarterCountdownIntent, in context: Context) async -> QuarterCountdownEntry {
    let now = Date()
    return QuarterCountdownEntry(
      date: now,
      countdown: QuarterCountdown(date: now, quarter: configuration.quarter.number, year: configuration.year)
    )
  }

  func timeline(for configuration: QuarterCountdownIntent, in context: Context) async -> Timeline<QuarterCountdownEntry> {
    quarterCountdownTimeline(now: Date(), quarter: configuration.quarter.number, year: configuration.year)
  }
}

@available(iOS 17.0, *)
struct QuarterCountdownWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "QuarterCountdownWidget", intent: QuarterCountdownIntent.self,
      provider: ConfigurableQuarterProvider()
    ) { entry in
      QuarterCountdownView(countdown: entry.countdown)
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName("Fim do trimestre")
    .description("Só os dias que faltam para terminar o trimestre escolhido.")
    .supportedFamilies([.accessoryCircular])
    .contentMarginsDisabled()
  }
}

private struct QuarterCountdownView: View {
  let countdown: QuarterCountdown

  var body: some View {
    VStack(spacing: 0) {
      Text(countdown.quarterLabel)
        .font(.system(size: 9, weight: .medium, design: .rounded))
        .foregroundStyle(.secondary)
      Text("\(countdown.daysRemaining)")
        .font(.system(size: 25, weight: .bold, design: .rounded))
        .monospacedDigit()
        .minimumScaleFactor(0.7)
        .lineLimit(1)
      Text(countdown.unitLabel)
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(.secondary)
    }
    .frame(width: 54, height: 54)
    .background(.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(countdown.accessibilityLabel)
  }
}

private struct OkrWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: OkrWidgetSnapshot?
}

private struct OkrWidgetSnapshot {
  let objectiveTitle: String
  let cycleLabel: String
  let objectiveProgress: Double
  let objectivePercentText: String
  let keyResultTitle: String
  let keyResultProgress: Double
  let keyResultPercentText: String
  let keyResultValueText: String
  let statusText: String
  let promptText: String
  let daysRemaining: Int
  let daysRemainingText: String
  let cycleEndDate: Date
  let updatedAt: Date

  static let appGroupId = "group.app.minharotina.mobile"
  static let snapshotKey = "okr_widget_snapshot_v1"

  init?(_ dictionary: [String: Any]) {
    guard
      let objectiveTitle = dictionary["objectiveTitle"] as? String,
      let cycleLabel = dictionary["cycleLabel"] as? String,
      let objectiveProgress = dictionary["objectiveProgress"] as? Double,
      let objectivePercentText = dictionary["objectivePercentText"] as? String,
      let keyResultTitle = dictionary["keyResultTitle"] as? String,
      let keyResultProgress = dictionary["keyResultProgress"] as? Double,
      let keyResultPercentText = dictionary["keyResultPercentText"] as? String,
      let keyResultValueText = dictionary["keyResultValueText"] as? String,
      let statusText = dictionary["statusText"] as? String,
      let promptText = dictionary["promptText"] as? String,
      let daysRemaining = dictionary["daysRemaining"] as? Int,
      let daysRemainingText = dictionary["daysRemainingText"] as? String,
      let cycleEndTimestamp = dictionary["cycleEndTimestamp"] as? Double,
      let updatedAtTimestamp = dictionary["updatedAtTimestamp"] as? Double
    else {
      return nil
    }

    self.objectiveTitle = objectiveTitle
    self.cycleLabel = cycleLabel
    self.objectiveProgress = min(max(objectiveProgress, 0), 1)
    self.objectivePercentText = objectivePercentText
    self.keyResultTitle = keyResultTitle
    self.keyResultProgress = min(max(keyResultProgress, 0), 1)
    self.keyResultPercentText = keyResultPercentText
    self.keyResultValueText = keyResultValueText
    self.statusText = statusText
    self.promptText = promptText
    self.daysRemaining = daysRemaining
    self.daysRemainingText = daysRemainingText
    self.cycleEndDate = Date(timeIntervalSince1970: cycleEndTimestamp)
    self.updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
  }

  static func load() -> OkrWidgetSnapshot? {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let dictionary = defaults.dictionary(forKey: snapshotKey)
    else {
      return nil
    }

    return OkrWidgetSnapshot(dictionary)
  }

  static var placeholder: OkrWidgetSnapshot {
    OkrWidgetSnapshot(
      objectiveTitle: "Aumentar MRR do produto",
      cycleLabel: "Q3 2026",
      objectiveProgress: 0.54,
      objectivePercentText: "54%",
      keyResultTitle: "Receita nova do trimestre",
      keyResultProgress: 0.42,
      keyResultPercentText: "42%",
      keyResultValueText: "R$ 42k / R$ 100k",
      statusText: "Em risco",
      promptText: "Próxima ação: revisar pipeline comercial",
      daysRemaining: 39,
      daysRemainingText: "39 dias restantes",
      cycleEndDate: Calendar.current.date(byAdding: .day, value: 39, to: Date()) ?? Date(),
      updatedAt: Date()
    )
  }

  init(
    objectiveTitle: String,
    cycleLabel: String,
    objectiveProgress: Double,
    objectivePercentText: String,
    keyResultTitle: String,
    keyResultProgress: Double,
    keyResultPercentText: String,
    keyResultValueText: String,
    statusText: String,
    promptText: String,
    daysRemaining: Int,
    daysRemainingText: String,
    cycleEndDate: Date,
    updatedAt: Date
  ) {
    self.objectiveTitle = objectiveTitle
    self.cycleLabel = cycleLabel
    self.objectiveProgress = objectiveProgress
    self.objectivePercentText = objectivePercentText
    self.keyResultTitle = keyResultTitle
    self.keyResultProgress = keyResultProgress
    self.keyResultPercentText = keyResultPercentText
    self.keyResultValueText = keyResultValueText
    self.statusText = statusText
    self.promptText = promptText
    self.daysRemaining = daysRemaining
    self.daysRemainingText = daysRemainingText
    self.cycleEndDate = cycleEndDate
    self.updatedAt = updatedAt
  }

  func daysRemaining(at date: Date) -> Int {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: date)
    let end = calendar.startOfDay(for: cycleEndDate)
    return calendar.dateComponents([.day], from: start, to: end).day ?? daysRemaining
  }

  func daysRemainingText(at date: Date) -> String {
    let value = daysRemaining(at: date)
    if value < 0 { return "Ciclo encerrado" }
    if value == 0 { return "Termina hoje" }
    if value == 1 { return "1 dia restante" }
    return "\(value) dias restantes"
  }
}

private struct OkrWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> OkrWidgetEntry {
    OkrWidgetEntry(date: Date(), snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (OkrWidgetEntry) -> Void) {
    let snapshot = OkrWidgetSnapshot.load() ?? .placeholder
    completion(OkrWidgetEntry(date: Date(), snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<OkrWidgetEntry>) -> Void) {
    let snapshot = OkrWidgetSnapshot.load()
    let now = Date()

    let calendar = Calendar.current
    var entries = [OkrWidgetEntry(date: now, snapshot: snapshot)]

    for dayOffset in 1...32 {
      guard let nextDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
        continue
      }
      let refreshDate = calendar.date(
        bySettingHour: 0,
        minute: 0,
        second: 0,
        of: nextDate
      ) ?? nextDate
      entries.append(OkrWidgetEntry(date: refreshDate, snapshot: snapshot))
    }

    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

struct OkrReminderWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "OkrReminderWidget", provider: OkrWidgetProvider()) { entry in
      OkrReminderWidgetView(entry: entry)
    }
    .configurationDisplayName("Foco do OKR")
    .description("Mostra o KR mais crítico, o prazo do ciclo e a próxima ação.")
    .supportedFamilies([
      .systemSmall,
      .systemMedium,
      .accessoryInline,
      .accessoryCircular,
      .accessoryRectangular,
    ])
  }
}

private struct OkrReminderWidgetView: View {
  @Environment(\.widgetFamily) private var family

  let entry: OkrWidgetEntry

  var body: some View {
    switch family {
    case .systemSmall:
      smallView
    case .systemMedium:
      mediumView
    case .accessoryInline:
      inlineView
    case .accessoryCircular:
      circularView
    case .accessoryRectangular:
      rectangularView
    default:
      mediumView
    }
  }

  private var snapshot: OkrWidgetSnapshot? {
    entry.snapshot
  }

  private var smallView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Color(red: 0.91, green: 0.36, blue: 0.20))

      if let snapshot {
        VStack(alignment: .leading, spacing: 8) {
          Text(snapshot.keyResultPercentText)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(.white)

          Text(snapshot.keyResultTitle)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(3)

          Spacer(minLength: 0)

          Text(snapshot.daysRemainingText(at: entry.date))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.92))
            .lineLimit(1)
        }
        .padding(14)
      } else {
        EmptyOkrWidgetView(label: "Crie um OKR")
      }
    }
  }

  private var mediumView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(Color(red: 0.16, green: 0.32, blue: 0.49))

      if let snapshot {
        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
              Text(snapshot.cycleLabel)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.75))
              Text(snapshot.objectiveTitle)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
              Text(snapshot.keyResultPercentText)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
              Text(snapshot.daysRemainingText(at: entry.date))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
            }
          }

          VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.keyResultTitle)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.white)
              .lineLimit(1)
            Text(snapshot.keyResultValueText)
              .font(.caption)
              .foregroundStyle(.white.opacity(0.75))
              .lineLimit(1)
            ProgressView(value: snapshot.keyResultProgress)
              .tint(.white)
          }

          Spacer(minLength: 0)

          HStack(alignment: .bottom) {
            Text(snapshot.statusText)
              .font(.caption.weight(.bold))
              .foregroundStyle(.white)
              .lineLimit(1)

            Spacer(minLength: 8)

            Text(snapshot.promptText)
              .font(.caption2)
              .foregroundStyle(.white.opacity(0.8))
              .lineLimit(2)
              .multilineTextAlignment(.trailing)
          }
        }
        .padding(16)
      } else {
        EmptyOkrWidgetView(label: "Sem OKR ativo")
      }
    }
  }

  private var inlineView: some View {
    let countdown = QuarterCountdown(date: entry.date)
    return Text("\(countdown.quarterLabel) · \(countdown.daysRemaining) \(countdown.unitLabel)")
  }

  private var circularView: some View {
    QuarterCountdownView(countdown: QuarterCountdown(date: entry.date))
  }

  private var rectangularView: some View {
    QuarterCountdownView(countdown: QuarterCountdown(date: entry.date))
  }
}

private struct EmptyOkrWidgetView: View {
  let label: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: "scope")
        .font(.title2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.92))
      Text(label)
        .font(.headline.weight(.bold))
        .foregroundStyle(.white)
      Text("Adicione objetivos para manter o foco visível.")
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.82))
        .lineLimit(3)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(14)
  }
}
