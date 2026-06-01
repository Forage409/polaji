import SwiftUI

enum VIPPaywallContext {
    case general
    case aiTrial
    case quota
    case tone
    case watermark
    case theme
    case publisherAI

    var subtitle: String {
        switch self {
        case .aiTrial: return "先看看 AI 能把这张结果图改得多有梗。"
        case .quota: return "免费 AI 次数已用完，升级后每天可以优化更多次。"
        case .tone: return "VIP 可以把结果切换成毒舌、可爱、抽象、正经或朋友圈风。"
        case .watermark: return "VIP 导出的结果图不带水印，更适合直接分享。"
        case .theme: return "VIP 可以解锁全部潮流手绘主题包。"
        case .publisherAI: return "VIP 发布者可以让 AI 自动生成整套玩法文案。"
        case .general: return "用 AI 把普通结果变成更适合分享的朋友圈神评。"
        }
    }
}

struct VIPPaywallView: View {
    let context: VIPPaywallContext
    let freeTrialRemaining: Int?
    let onTryFree: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan = "yearly"
    @State private var showPlaceholderAlert = false

    init(
        context: VIPPaywallContext = .general,
        freeTrialRemaining: Int? = nil,
        onTryFree: (() -> Void)? = nil
    ) {
        self.context = context
        self.freeTrialRemaining = freeTrialRemaining
        self.onTryFree = onTryFree
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                benefits
                plans
                actionArea
                legalLinks
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF4C9"), Color(hex: "FFF9E8"), Color.themeBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("整活局 VIP")
        .navigationBarTitleDisplayMode(.inline)
        .alert("订阅通道即将开放", isPresented: $showPlaceholderAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("本轮已接通真实 AI 能力和次数限制。App Store 订阅与恢复购买将在正式上架配置完成后开放。")
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image.bundle("vip_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
            Text("让结果更好笑，更像人写的")
                .font(.system(size: 25, weight: .heavy))
                .multilineTextAlignment(.center)
            Text(context.subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var benefits: some View {
        let items = [
            ("wand.and.stars", "AI 爆梗优化"),
            ("quote.bubble.fill", "AI 换语气"),
            ("doc.text.fill", "AI 帮写玩法"),
            ("drop.fill", "去水印"),
            ("paintpalette.fill", "全部主题包"),
            ("arrow.clockwise.circle.fill", "更多 AI 次数")
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.1) { item in
                HStack(spacing: 8) {
                    Image(systemName: item.0)
                        .foregroundColor(Color(hex: "B58900"))
                    Text(item.1)
                        .font(.system(size: 13, weight: .bold))
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
            }
        }
    }

    private var plans: some View {
        HStack(spacing: 12) {
            planCard(id: "monthly", title: "月度 VIP", price: "¥8", hint: "每月自动续费")
            planCard(id: "yearly", title: "年度 VIP", price: "¥38", hint: "更划算")
        }
    }

    private func planCard(id: String, title: String, price: String, hint: String) -> some View {
        let selected = selectedPlan == id
        return Button(action: { selectedPlan = id }) {
            VStack(spacing: 7) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(price).font(.system(size: 28, weight: .heavy))
                Text(hint).font(.system(size: 11)).foregroundColor(.themeTextSecondary)
            }
            .foregroundColor(.themeTextMain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selected ? Color.themePrimary.opacity(0.24) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? Color.themePrimary : Color.gray.opacity(0.12), lineWidth: selected ? 2 : 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var actionArea: some View {
        VStack(spacing: 12) {
            Button(action: { showPlaceholderAlert = true }) {
                Text("立即开通")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.themePrimary)
                    .cornerRadius(27)
            }

            if let onTryFree {
                Button {
                    VipManager.shared.markAITrialPaywallSeen()
                    dismiss()
                    onTryFree()
                } label: {
                    Text("先免费优化一次，今日剩余 \(freeTrialRemaining ?? 3) 次")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextMain)
                }
            }

            Button("恢复购买") { showPlaceholderAlert = true }
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 12) {
            NavigationLink("用户协议") { LegalDocView(kind: .terms) }
            Text("·")
            NavigationLink("隐私政策") { LegalDocView(kind: .privacy) }
        }
        .font(.system(size: 12))
        .foregroundColor(.themeTextSecondary)
    }
}

typealias PayWallView = VIPPaywallView
