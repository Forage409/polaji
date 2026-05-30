import SwiftUI
 
struct MyOrdersView: View {
    @ObservedObject private var vip = VipManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if vip.isVip {
                    activeVipCard
                } else {
                    emptyState
                }
                
                ordersExplanation
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("我的订单")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var activeVipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image.bundle("vip_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(vip.planName.isEmpty ? "整活局 VIP" : vip.planName)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                    Text(vip.expiryDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Text("已激活")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.themeSuccessGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.themeSuccessGreen.opacity(0.15))
                    .cornerRadius(10)
            }
            Divider()
            HStack {
                infoCell(title: "订单类型", value: "前端体验版")
                Spacer()
                infoCell(title: "购买渠道", value: "本地激活")
                Spacer()
                infoCell(title: "支付状态", value: "未实际扣费")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func infoCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.themeTextSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextMain)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "tray.fill")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundColor(Color(hex: "B58900"))
            }
            Text("还没有订单")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Text("开通整活局 VIP 即可去除水印、无限生成。")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
            NavigationLink(destination: PayWallView()) {
                Text("去开通会员")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.themePrimary)
                    .cornerRadius(22)
                    .shadow(color: Color.themePrimary.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var ordersExplanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("说明")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeTextMain)
            Text("正式版会接入 App Store 内购通道，购买记录将通过 StoreKit 自动同步至本页面，可在此查看订阅状态、续费时间与历史发票。当前为前端体验版，购买按钮为占位。")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}
