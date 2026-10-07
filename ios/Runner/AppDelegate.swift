import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let timezoneChannel = FlutterMethodChannel(
        name: "app.minharotina.mobile/timezone",
        binaryMessenger: controller.binaryMessenger
      )
      let liveActivityChannel = FlutterMethodChannel(
        name: "app.minharotina.mobile/live_activity",
        binaryMessenger: controller.binaryMessenger
      )
      let okrWidgetChannel = FlutterMethodChannel(
        name: "app.minharotina.mobile/okr_widgets",
        binaryMessenger: controller.binaryMessenger
      )

      timezoneChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "getLocalTimezone":
          result(TimeZone.current.identifier)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      liveActivityChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "syncDailyGoal":
          guard #available(iOS 16.1, *) else {
            result(nil)
            return
          }
          guard let payload = DailyGoalLiveActivityPayload(arguments: call.arguments) else {
            result(
              FlutterError(
                code: "invalid_payload",
                message: "Invalid daily goal payload.",
                details: nil
              )
            )
            return
          }

          Task {
            do {
              try await DailyGoalLiveActivityManager.shared.sync(payload)
              result(nil)
            } catch {
              result(
                FlutterError(
                  code: "live_activity_sync_failed",
                  message: error.localizedDescription,
                  details: nil
                )
              )
            }
          }
        case "endDailyGoal":
          guard #available(iOS 16.1, *) else {
            result(nil)
            return
          }

          Task {
            await DailyGoalLiveActivityManager.shared.endAll()
            result(nil)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      okrWidgetChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "syncOkrWidget":
          guard let payload = OkrWidgetPayload(arguments: call.arguments) else {
            result(
              FlutterError(
                code: "invalid_payload",
                message: "Invalid OKR widget payload.",
                details: nil
              )
            )
            return
          }

          OkrWidgetStore.save(payload)
          result(nil)
        case "clearOkrWidget":
          OkrWidgetStore.clear()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private struct OkrWidgetPayload {
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
  let cycleEndTimestamp: Double
  let updatedAtTimestamp: Double

  init?(arguments: Any?) {
    guard
      let map = arguments as? [String: Any],
      let objectiveTitle = map["objectiveTitle"] as? String,
      let cycleLabel = map["cycleLabel"] as? String,
      let objectiveProgress = map["objectiveProgress"] as? Double,
      let objectivePercentText = map["objectivePercentText"] as? String,
      let keyResultTitle = map["keyResultTitle"] as? String,
      let keyResultProgress = map["keyResultProgress"] as? Double,
      let keyResultPercentText = map["keyResultPercentText"] as? String,
      let keyResultValueText = map["keyResultValueText"] as? String,
      let statusText = map["statusText"] as? String,
      let promptText = map["promptText"] as? String,
      let daysRemaining = map["daysRemaining"] as? Int,
      let daysRemainingText = map["daysRemainingText"] as? String,
      let cycleEndTimestamp = map["cycleEndTimestamp"] as? Double,
      let updatedAtTimestamp = map["updatedAtTimestamp"] as? Double
    else {
      return nil
    }

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
    self.cycleEndTimestamp = cycleEndTimestamp
    self.updatedAtTimestamp = updatedAtTimestamp
  }

  var dictionary: [String: Any] {
    [
      "objectiveTitle": objectiveTitle,
      "cycleLabel": cycleLabel,
      "objectiveProgress": objectiveProgress,
      "objectivePercentText": objectivePercentText,
      "keyResultTitle": keyResultTitle,
      "keyResultProgress": keyResultProgress,
      "keyResultPercentText": keyResultPercentText,
      "keyResultValueText": keyResultValueText,
      "statusText": statusText,
      "promptText": promptText,
      "daysRemaining": daysRemaining,
      "daysRemainingText": daysRemainingText,
      "cycleEndTimestamp": cycleEndTimestamp,
      "updatedAtTimestamp": updatedAtTimestamp,
    ]
  }
}

private enum OkrWidgetStore {
  static let appGroupId = "group.app.minharotina.mobile"
  static let snapshotKey = "okr_widget_snapshot_v1"

  static func save(_ payload: OkrWidgetPayload) {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
    defaults.set(payload.dictionary, forKey: snapshotKey)
    reload()
  }

  static func clear() {
    guard let defaults = UserDefaults(suiteName: appGroupId) else { return }
    defaults.removeObject(forKey: snapshotKey)
    reload()
  }

  static func reload() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }
}
