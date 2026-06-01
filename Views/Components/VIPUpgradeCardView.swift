import SwiftUI

struct VIPUpgradeCardView: View {
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            Image.bundle("vip_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            Text("已经整出 3 张图啦")
                .font(.system(size: 21, weight: .heavy))
            Text("试试 AI 爆梗优化，让下一张更像朋友圈神评。")
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
            Button("看看 AI VIP", action: onUpgrade)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeTextMain)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.themePrimary)
                .cornerRadius(24)
            Button("先继续玩", action: onDismiss)
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(22)
        .background(Color.white)
        .cornerRadius(22)
        .padding(20)
    }
}
