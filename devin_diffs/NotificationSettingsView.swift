import SwiftUI
import UserNotifications
 
struct NotificationSettingsView: View {
    @State private var systemAuthorized = false
    @State private var systemDenied = false
    @State private var dailyReminderEnabled = UserDefaults.standard.bool(forKey: "ZhengHuoJu_DailyReminder")
    @State private var newTemplateEnabled = UserDefaults.standard.object(forKey: "ZhengHuoJu_NewTemplateNotify") as? Bool ?? true
    @State private var showSettingsAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                statusBanner
                
                VStack(spacing: 0) {
                    toggleRow(
                        title: "每日整活提醒",
                        subtitle: "每天 20:00 提醒你生成今日人设卡",
                        binding: $dailyReminderEnabled,
                        onChange: { handleDailyReminderChange($0) }
                    )
                    Divider().padding(.horizontal, 16)
                    toggleRow(
                        title: "新模板上线提醒",
                        subtitle: "上新有梗模板时通知你",
                        binding: $newTemplateEnabled,
                        onChange: { value in
                            UserDefaults.standard.set(value, forKey: "ZhengHuoJu_NewTemplateNotify")
                        }
                    )
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 16)
                
                Text("整活局不会推送任何营销内容。本地通知由系统调度，不依赖任何服务器。")
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshAuthorization)
        .alert(isPresented: $showSettingsAlert) {
            Alert(
                title: Text("通知权限未开启"),
                message: Text("请前往系统设置开启「整活局」通知权限后再试。"),
                primaryButton: .default(Text("去设置"), action: openSystemSettings),
                secondaryButton: .cancel(Text("取消"), action: {
                    dailyReminderEnabled = false
                })
            )
        }
    }
    
    private var statusBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: systemAuthorized ? "bell.fill" : (systemDenied ? "bell.slash.fill" : "bell"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text(statusSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if systemDenied {
                Button(action: openSystemSettings) {
                    Text("去设置")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.themePrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    private var statusColor: Color {
        if systemAuthorized { return Color.themeSuccessGreen }
        if systemDenied { return Color.themeWarningPink }
        return Color.themeTextSecondary
    }
    
    private var statusTitle: String {
        if systemAuthorized { return "通知权限已开启" }
        if systemDenied { return "通知权限已被拒绝" }
        return "尚未请求通知权限"
    }
    
    private var statusSubtitle: String {
        if systemAuthorized { return "你可以在下面分别设置不同类型的提醒。" }
        if systemDenied { return "前往系统设置开启通知权限，才能收到整活提醒。" }
        return "开启下方任一开关时会请求系统通知授权。"
    }
    
    private func toggleRow(title: String, subtitle: String, binding: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.themeTextMain)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Color.themePrimary)
                .onChange(of: binding.wrappedValue) { value in
                    onChange(value)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    private func handleDailyReminderChange(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "ZhengHuoJu_DailyReminder")
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        scheduleDailyReminder()
                        refreshAuthorization()
                    } else {
                        dailyReminderEnabled = false
                        UserDefaults.standard.set(false, forKey: "ZhengHuoJu_DailyReminder")
                        refreshAuthorization()
                        showSettingsAlert = true
                    }
                }
            }
        } else {
            cancelDailyReminder()
        }
    }
    
    private func refreshAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                systemAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                systemDenied = settings.authorizationStatus == .denied
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "整活局"
        content.body = "今天还没整活？快来生成你今天的专属人设卡 🎉"
        content.sound = .default
        
        var date = DateComponents()
        date.hour = 20
        date.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "ZhengHuoJu_DailyReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ZhengHuoJu_DailyReminder"])
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

SettingsView.swift
