import SwiftUI
 
struct SettingsView: View {
    @ObservedObject private var vip = VipManager.shared
    @ObservedObject private var session = AccountSessionManager.shared
    
    @State private var cacheSize: Int64 = 0
    @State private var isClearing = false
    @State private var showClearAlert = false
    @State private var showClearResult = false
    @State private var clearResultMessage = ""
    @State private var showDeleteConfirm = false
    
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                section(title: "隐私与通知") {
                    NavigationLink(destination: LegalDocView(kind: .privacy)) {
                        row(title: "隐私设置", subtitle: "查看完整隐私政策与权限说明", trailing: .chevron)
                    }
                    divider()
                    NavigationLink(destination: NotificationSettingsView()) {
                        row(title: "通知设置", subtitle: "本地提醒与系统通知权限", trailing: .chevron)
                    }
                }
                
                section(title: "存储") {
                    Button(action: { showClearAlert = true }) {
                        row(
                            title: "清除缓存",
                            subtitle: isClearing ? "正在清理…" : "可释放本地缓存与临时文件",
                            trailing: .text(CacheManager.formatBytes(cacheSize))
                        )
                    }
                    .disabled(isClearing)
                }
                
                section(title: "云端服务") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("账号资料、发布玩法、公开作品、创作者分析和 VIP 状态会同步到整活局云端。浏览历史和未发布的本地作品仍只保存在当前设备。")
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }

                section(title: "账号") {
                    Button {
                        Task { await session.logout() }
                    } label: {
                        row(title: "退出登录", subtitle: "保留云端账号数据，可重新登录恢复", trailing: .chevron)
                    }
                    divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        row(title: "注销账号", subtitle: "撤销登录并按隐私政策处理云端数据", trailing: .chevron)
                    }
                }
                
                section(title: "关于") {
                    NavigationLink(destination: AboutView()) {
                        row(title: "关于整活局", subtitle: "App 介绍 / 协议", trailing: .chevron)
                    }
                    divider()
                    row(title: "当前版本", subtitle: "Build \(build)", trailing: .text("V \(version)"))
                }
                
                section(title: "测试入口") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("调试 VIP 开关")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.themeTextMain)
                            Text("正式版会接入 App Store 内购，目前用此开关临时切换 VIP 状态体验去水印效果。")
                                .font(.system(size: 12))
                                .foregroundColor(.themeTextSecondary)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { vip.isVip },
                            set: { newValue in
                                if newValue {
                                    vip.activate(plan: "调试 VIP", expiry: nil)
                                } else {
                                    vip.deactivate()
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(Color.themePrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCacheSize()
        }
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("确认清除缓存？"),
                message: Text("将清理临时文件与图片缓存（不会删除你已生成的作品）。"),
                primaryButton: .destructive(Text("清除"), action: performClear),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("缓存清理完成", isPresented: $showClearResult) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(clearResultMessage)
        }
        .confirmationDialog("确认注销账号？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("注销账号", role: .destructive) {
                Task {
                    do {
                        try await AccountService.shared.deleteAccount()
                        await MainActor.run { session.clearLocalSession() }
                    } catch {
                        await MainActor.run {
                            clearResultMessage = "注销失败，请检查网络后重试。"
                            showClearResult = true
                        }
                    }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("注销后当前会话会失效，本人发布的玩法会隐藏，历史公开作品会匿名化。该操作无法直接撤销。")
        }
    }
    
    private enum TrailingStyle {
        case chevron
        case text(String)
    }
    
    private func row(title: String, subtitle: String?, trailing: TrailingStyle) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.themeTextMain)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            case .text(let txt):
                Text(txt)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content() }
                .background(Color.white)
                .cornerRadius(14)
                .padding(.horizontal, 16)
        }
    }
    
    private func divider() -> some View {
        Divider()
            .padding(.horizontal, 16)
    }
    
    private func refreshCacheSize() {
        DispatchQueue.global(qos: .userInitiated).async {
            let size = CacheManager.computeCacheSize()
            DispatchQueue.main.async {
                cacheSize = size
            }
        }
    }
    
    private func performClear() {
        isClearing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let before = CacheManager.computeCacheSize()
            CacheManager.clearCache()
            let after = CacheManager.computeCacheSize()
            let freed = max(0, before - after)
            DispatchQueue.main.async {
                cacheSize = after
                isClearing = false
                clearResultMessage = freed > 0
                    ? "已释放 \(CacheManager.formatBytes(freed)) 空间。"
                    : "暂无可清理的缓存。"
                showClearResult = true
            }
        }
    }
}
