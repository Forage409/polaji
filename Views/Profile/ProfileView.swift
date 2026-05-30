import SwiftUI
 
struct ProfileView: View {
    @ObservedObject private var profile = UserProfileStore.shared
    @ObservedObject private var vip = VipManager.shared
    @ObservedObject private var works = WorksStore.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerBar
                    userCard
                    statsCard
                    vipBanner
                    menuList
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var headerBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Text("我的")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                Text("🎉")
                    .font(.system(size: 22))
            }
            Spacer()
            NavigationLink(destination: PayWallView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(vip.isVip ? Color.themePrimary : Color.themePrimary.opacity(0.22))
                        .frame(width: 70, height: 32)
                    HStack(spacing: 4) {
                        Image.bundle("vip_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .grayscale(vip.isVip ? 0.0 : 0.55)
                            .opacity(vip.isVip ? 1.0 : 0.85)
                        Text("VIP")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.themeTextMain)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            NavigationLink(destination: SettingsView()) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    Image.bundle("settings_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 10)
    }
    
    private var userCard: some View {
        NavigationLink(destination: EditProfileView()) {
            HStack(spacing: 14) {
                AvatarImage(name: profile.avatarName)
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(profile.nickname)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.themeTextMain)
                            .lineLimit(1)
                        if vip.isVip {
                            Text("VIP")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.themeTextMain)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.themePrimary)
                                .cornerRadius(6)
                        }
                    }
                    Text("ID: \(profile.userId)")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary)
                    Text(profile.bio)
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statsCard: some View {
        NavigationLink(destination: MyWorksView()) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("我的作品")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                    Text("\(works.works.count)")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                    Text("已生成的整活卡片")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.themePrimary.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "B58900"))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var vipBanner: some View {
        NavigationLink(destination: PayWallView()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 52, height: 52)
                    Image.bundle("vip_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(vip.isVip ? "你已是整活局 VIP" : "整活局 VIP")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.themeTextMain)
                    Text(vip.isVip ? vip.expiryDisplay : "解锁全部模板，去除水印")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextMain.opacity(0.75))
                        .lineLimit(2)
                }
                Spacer()
                Text(vip.isVip ? "续费" : "立即升级")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "FFE070"), Color(hex: "FFD43B")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: Color.themePrimary.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(icon: "sparkles.rectangle.stack.fill", color: Color.themePrimary, title: "创作者中心", subtitle: "管理我的玩法，查看数据漏斗") {
                CreatorCenterView()
            }
            divider()
            menuRow(icon: "doc.text.fill", color: Color(hex: "FFB300"), title: "我的订单", subtitle: "查看会员订单与支付记录") {
                MyOrdersView()
            }
            divider()
            menuRow(icon: "gift.fill", color: Color(hex: "FF6B8A"), title: "我的邀请码", subtitle: "邀请好友领整活会员") {
                InviteCodeView()
            }
            divider()
            menuRow(icon: "clock.fill", color: Color(hex: "7B61FF"), title: "浏览历史", subtitle: "看过的模板都在这") {
                BrowseHistoryView()
            }
            divider()
            menuRow(icon: "bubble.left.fill", color: Color(hex: "4CAF7D"), title: "意见反馈", subtitle: "告诉我们你想要的整活玩法") {
                FeedbackView()
            }
            divider()
            menuRow(icon: "info.circle.fill", color: Color(hex: "5BC0EB"), title: "关于整活局", subtitle: "版本 / 协议 / 开发者") {
                AboutView()
            }
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    @ViewBuilder
    private func menuRow<Destination: View>(icon: String, color: Color, title: String, subtitle: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.themeTextMain)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func divider() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 66)
    }
}
