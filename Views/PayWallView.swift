import SwiftUI
 
struct PayWallPlan: Identifiable, Hashable {
    let id: String
    let title: String
    let price: String
    let originalPrice: String?
    let badge: String?
    let perDayHint: String?
    let durationLabel: String
    let highlight: Bool
}
 
struct PayWallView: View {
    @ObservedObject private var vip = VipManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPlanId: String = "lifetime"
    @State private var showPurchaseAlert = false
    
    private let plans: [PayWallPlan] = [
        PayWallPlan(id: "monthly", title: "月度会员", price: "¥8", originalPrice: "¥18", badge: nil, perDayHint: "约 ¥0.27/天", durationLabel: "30 天", highlight: false),
        PayWallPlan(id: "yearly", title: "年度会员", price: "¥38", originalPrice: "¥98", badge: "省 60%", perDayHint: "约 ¥0.10/天", durationLabel: "365 天", highlight: false),
        PayWallPlan(id: "lifetime", title: "永久会员", price: "¥68", originalPrice: "¥198", badge: "最划算", perDayHint: "一次买断，终身使用", durationLabel: "永久", highlight: true)
    ]
    
    private let benefits: [(String, String, String)] = [
        ("nosign", "去除水印", "保存导出的整活卡片不再带「整活局」水印"),
        ("edit", "官方玩法自定义文案", "在官方玩法生成前补充一段专属文案")
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "FFF6D6"), Color(hex: "FFFCEC"), Color.themeBackground]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroSection
                    benefitGrid
                    plansSection
                    Text("内购为虚拟服务，购买后不支持退款。会员仅供本地体验，未来接入正式支付通道。")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 4)
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            
            VStack {
                Spacer()
                purchaseBar
            }
        }
        .navigationTitle("开通整活局 VIP")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showPurchaseAlert) {
            Alert(
                title: Text("支付通道即将开放"),
                message: Text("当前为前端体验版，购买功能将在正式版接入 App Store 内购。\n\n如果你希望立刻体验 VIP 权益（去水印等），可前往「设置」开启调试 VIP 开关。"),
                dismissButton: .default(Text("我知道了"))
            )
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image.bundle("vip_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                Text("整活局 VIP")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.themeTextMain)
            }
            Text(vip.isVip ? "你已是 VIP — \(vip.expiryDisplay)" : "去除水印，体验官方玩法自定义文案")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.themePrimary.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    private var benefitGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("会员特权")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(0..<benefits.count, id: \.self) { idx in
                    let item = benefits[idx]
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.themePrimary.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: symbolFor(item.0))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "B58900"))
                        }
                        Text(item.1)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeTextMain)
                        Text(item.2)
                            .font(.system(size: 11))
                            .foregroundColor(.themeTextSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择套餐")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.themeTextMain)
                .padding(.horizontal, 4)
            
            HStack(spacing: 10) {
                ForEach(plans) { plan in
                    planCard(plan)
                        .onTapGesture {
                            selectedPlanId = plan.id
                        }
                }
            }
        }
    }
    
    private func planCard(_ plan: PayWallPlan) -> some View {
        let isSelected = plan.id == selectedPlanId
        return VStack(spacing: 6) {
            if let badge = plan.badge {
                Text(badge)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.themeWarningPink)
                    .cornerRadius(8)
            } else {
                Color.clear.frame(height: 16)
            }
            Text(plan.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
            Text(plan.price)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(isSelected ? Color(hex: "B58900") : .themeTextMain)
            if let original = plan.originalPrice {
                Text(original)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
                    .strikethrough(true, color: .themeTextSecondary)
            }
            Text(plan.perDayHint ?? plan.durationLabel)
                .font(.system(size: 10))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.themePrimary.opacity(0.18) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.themePrimary : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
    
    private var purchaseBar: some View {
        VStack(spacing: 8) {
            Button(action: { showPurchaseAlert = true }) {
                HStack(spacing: 8) {
                    Image.bundle("vip_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(vip.isVip ? "续费 / 升级" : "立即开通 \(currentPlan.price)")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color(hex: "FFE070"), Color(hex: "FFD43B")]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(27)
                .shadow(color: Color.themePrimary.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            HStack(spacing: 16) {
                Button("恢复购买") { showPurchaseAlert = true }
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
                Text("·").foregroundColor(.themeTextSecondary)
                NavigationLink("用户协议") { LegalDocView(kind: .terms) }
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
                Text("·").foregroundColor(.themeTextSecondary)
                NavigationLink("隐私政策") { LegalDocView(kind: .privacy) }
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0), Color.white]), startPoint: .top, endPoint: .bottom)
        )
    }
    
    private var currentPlan: PayWallPlan {
        plans.first(where: { $0.id == selectedPlanId }) ?? plans[2]
    }
    
    private func symbolFor(_ key: String) -> String {
        switch key {
        case "nosign": return "nosign"
        case "infinity": return "infinity"
        case "crown": return "crown.fill"
        case "hd": return "rectangle.compress.vertical"
        case "paint": return "paintpalette.fill"
        case "edit": return "square.and.pencil"
        default: return "sparkles"
        }
    }
}
