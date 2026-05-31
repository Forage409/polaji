import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var manager = AppNotificationManager.shared
    @State private var showSettingsAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                statusBanner

                VStack(spacing: 0) {
                    toggleRow(
                        title: "每日整活提醒",
                        subtitle: "每天 20:00 提醒你生成今日人设卡",
                        binding: Binding(
                            get: { manager.dailyReminderEnabled },
                            set: { manager.setDailyReminder($0, onDenied: showDeniedAlert) }
                        )
                    )
                    Divider().padding(.horizontal, 16)
                    toggleRow(
                        title: "新模板上线提醒",
                        subtitle: "App 启动或返回前台时检查真实上新玩法",
                        binding: Binding(
                            get: { manager.newTemplateEnabled },
                            set: { manager.setNewTemplateReminder($0, onDenied: showDeniedAlert) }
                        )
                    )
                }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 16)

                Text("每日提醒由系统本地调度。新模板提醒会在 App 启动或返回前台时拉取真实模板列表，发现上新后发送通知。")
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
        .onAppear(perform: manager.refresh)
        .alert(isPresented: $showSettingsAlert) {
            Alert(
                title: Text("通知权限未开启"),
                message: Text("请前往系统设置开启「整活局」通知权限后再试。"),
                primaryButton: .default(Text("去设置"), action: openSystemSettings),
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: manager.systemAuthorized ? "bell.fill" : (manager.systemDenied ? "bell.slash.fill" : "bell"))
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
            }
            Spacer()
            if manager.systemDenied {
                Button("去设置", action: openSystemSettings)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.themePrimary)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }

    private var statusColor: Color {
        if manager.systemAuthorized { return .themeSuccessGreen }
        if manager.systemDenied { return .themeWarningPink }
        return .themeTextSecondary
    }

    private var statusTitle: String {
        if manager.systemAuthorized { return "通知权限已开启" }
        if manager.systemDenied { return "通知权限已被拒绝" }
        return "尚未请求通知权限"
    }

    private var statusSubtitle: String {
        manager.systemAuthorized ? "你可以分别控制两类提醒。" : "开启任一提醒时会请求系统通知授权。"
    }

    private func toggleRow(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack {
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
                .tint(.themePrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func showDeniedAlert() {
        showSettingsAlert = true
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
