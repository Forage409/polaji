import SwiftUI
 
struct InviteCodeView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFF6D6"), Color(hex: "FFE4EC"), Color(hex: "EDE7FF")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 28) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 120, height: 120)
                    Image.bundle("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(animate ? 8 : -8))
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: animate)
                }
                .shadow(color: Color.themePrimary.opacity(0.3), radius: 16, x: 0, y: 8)
                
                VStack(spacing: 12) {
                    Text("敬请期待")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                    
                    HStack(spacing: 6) {
                        Capsule().fill(Color.themePrimary).frame(width: 6, height: 6)
                        Text("Coming Soon")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "B58900"))
                            .tracking(2)
                        Capsule().fill(Color.themePrimary).frame(width: 6, height: 6)
                    }
                    
                    Text("邀请好友领会员的活动正在筹备中，\n上线后你可以在这里查看专属邀请码、邀请记录和奖励进度。")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                }
                
                VStack(spacing: 12) {
                    featureRow(icon: "gift.fill", color: Color(hex: "FF6B8A"), title: "邀请有礼", subtitle: "邀请 1 位好友赠送 7 天会员")
                    featureRow(icon: "person.2.fill", color: Color(hex: "7B61FF"), title: "邀请记录", subtitle: "实时查看好友是否完成注册")
                    featureRow(icon: "crown.fill", color: Color(hex: "FFB300"), title: "成长奖励", subtitle: "邀请越多，会员时长越长")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            .padding(.bottom, 60)
        }
        .navigationTitle("我的邀请码")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animate = true }
    }
    
    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
        .cornerRadius(14)
    }
}
