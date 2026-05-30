import SwiftUI

struct CreatorCenterView: View {
    @State private var publishedTemplatesCount = 5
    @State private var totalViews = 125000
    @State private var totalGenerates = 85000
    @State private var totalShares = 42000
    @State private var totalLikes = 13000
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Profile Info
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.themePrimary.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.themePrimary)
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("创作者中心")
                            .font(.system(size: 20, weight: .bold))
                        Text(UserProfileStore.shared.nickname)
                            .font(.system(size: 14))
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    statCard(title: "已发布玩法", value: "\(publishedTemplatesCount)", icon: "square.grid.2x2.fill", color: .blue)
                    statCard(title: "总浏览数", value: formatCount(totalViews), icon: "eye.fill", color: .purple)
                    statCard(title: "总生成数", value: formatCount(totalGenerates), icon: "wand.and.stars", color: .orange)
                    statCard(title: "总分享数", value: formatCount(totalShares), icon: "square.and.arrow.up.fill", color: .green)
                    statCard(title: "总获赞数", value: formatCount(totalLikes), icon: "heart.fill", color: .red)
                }
                .padding(.horizontal)
                
                // Actions
                VStack(spacing: 12) {
                    NavigationLink(destination: MyPublishedTemplatesView()) {
                        actionRow(title: "我的发布", icon: "doc.text.image")
                    }
                    actionRow(title: "草稿箱", icon: "doc.badge.gearshape")
                    actionRow(title: "创作者学院", icon: "graduationcap")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("创作者中心")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.themeTextSecondary)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.themeTextMain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func actionRow(title: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.themeTextMain)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeTextMain)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.themeTextSecondary)
                .font(.system(size: 14))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        }
        return "\(count)"
    }
}
