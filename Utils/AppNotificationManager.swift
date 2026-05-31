import Foundation
import Combine
import UserNotifications

final class AppNotificationManager: ObservableObject {
    static let shared = AppNotificationManager()

    private let dailyKey = "ZhengHuoJu_DailyReminder"
    private let newTemplateKey = "ZhengHuoJu_NewTemplateNotify"
    private let knownTemplateIdsKey = "ZhengHuoJu_KnownTemplateIds"
    private let dailyIdentifier = "ZhengHuoJu_DailyReminder"

    @Published private(set) var dailyReminderEnabled: Bool
    @Published private(set) var newTemplateEnabled: Bool
    @Published private(set) var systemAuthorized = false
    @Published private(set) var systemDenied = false

    private init() {
        let defaults = UserDefaults.standard
        dailyReminderEnabled = defaults.bool(forKey: dailyKey)
        newTemplateEnabled = defaults.object(forKey: newTemplateKey) as? Bool ?? false
    }

    func refresh() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.systemAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                self.systemDenied = settings.authorizationStatus == .denied
                if self.systemAuthorized && UserDefaults.standard.bool(forKey: self.dailyKey) {
                    self.scheduleDailyReminder()
                }
            }
        }
    }

    func setDailyReminder(_ enabled: Bool, onDenied: @escaping () -> Void) {
        guard enabled else {
            UserDefaults.standard.set(false, forKey: dailyKey)
            dailyReminderEnabled = false
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
            return
        }
        requestAuthorization(onDenied: onDenied) {
            self.scheduleDailyReminder()
        }
    }

    func setNewTemplateReminder(_ enabled: Bool, onDenied: @escaping () -> Void) {
        guard enabled else {
            UserDefaults.standard.set(false, forKey: newTemplateKey)
            newTemplateEnabled = false
            return
        }
        requestAuthorization(onDenied: onDenied) {
            UserDefaults.standard.set(true, forKey: self.newTemplateKey)
            self.newTemplateEnabled = true
            Task { await self.checkForNewTemplates() }
        }
    }

    @MainActor
    func checkForNewTemplates() async {
        guard newTemplateEnabled else { return }
        do {
            let templates = try await RemoteTemplateService.shared.fetchTemplates()
            let currentIds = Set(templates.map(\.id))
            let knownIds = Set(UserDefaults.standard.stringArray(forKey: knownTemplateIdsKey) ?? [])
            defer { UserDefaults.standard.set(Array(currentIds), forKey: knownTemplateIdsKey) }
            guard !knownIds.isEmpty else { return }
            guard let latest = templates.first(where: { !knownIds.contains($0.id) }) else { return }
            scheduleNewTemplateNotification(title: latest.title)
        } catch {
            print("Failed to check new templates: \(error.localizedDescription)")
        }
    }

    private func requestAuthorization(onDenied: @escaping () -> Void, onGranted: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.systemAuthorized = granted
                self.systemDenied = !granted
                if granted {
                    onGranted()
                } else {
                    onDenied()
                }
            }
        }
    }

    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "整活局"
        content.body = "今天还没整活？快来生成你今天的专属人设卡。"
        content.sound = .default

        var date = DateComponents()
        date.hour = 20
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: dailyIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                let enabled = error == nil
                UserDefaults.standard.set(enabled, forKey: self.dailyKey)
                self.dailyReminderEnabled = enabled
            }
        }
    }

    private func scheduleNewTemplateNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "整活局上新"
        content.body = "新玩法「\(title)」已经上线，来看看这次能整出什么效果。"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "ZhengHuoJu_NewTemplate_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}
