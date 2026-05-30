import SwiftUI

struct MyPublishedTemplatesView: View {
    @State private var templates: [RemoteTemplate] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if templates.isEmpty {
                    Text("暂无发布的玩法")
                        .foregroundColor(.themeTextSecondary)
                        .padding(.top, 100)
                } else {
                    ForEach(templates) { template in
                        NavigationLink(destination: TemplateStatsView(template: template)) {
                            publishedTemplateCard(template)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("我的发布")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if templates.isEmpty {
                loadData()
            }
        }
    }
    
    private func loadData() {
        RemoteCreatorService.shared.fetchMyPublishedTemplates { fetched in
            if let fetched = fetched {
                self.templates = fetched
            } else {
                self.templates = []
            }
        }
    }
    
    @ViewBuilder
    private func publishedTemplateCard(_ template: RemoteTemplate) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .overlay(
                    Text("无封面")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(template.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextMain)
                
                Text("状态: \(template.status == "published" ? "已发布" : "未知")")
                    .font(.system(size: 12))
                    .foregroundColor(.themePrimary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    statMini(icon: "eye", val: template.viewCount)
                    statMini(icon: "wand.and.stars", val: template.generateCount)
                    statMini(icon: "square.and.arrow.up", val: template.shareCount)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func statMini(icon: String, val: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(val)")
                .font(.system(size: 12))
        }
        .foregroundColor(.themeTextSecondary)
    }
}

struct TemplateStatsView: View {
    let template: RemoteTemplate
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.title)
                        .font(.system(size: 20, weight: .bold))
                    Text("发布于 \(template.createdAt)")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("数据漏斗")
                        .font(.system(size: 16, weight: .bold))
                    
                    funnelRow(title: "浏览数 (View)", count: template.viewCount, max: max(1, template.viewCount), color: .purple)
                    funnelRow(title: "点击开始 (Start)", count: template.startCount, max: max(1, template.viewCount), color: .blue)
                    funnelRow(title: "成功生成 (Generate)", count: template.generateCount, max: max(1, template.viewCount), color: .orange)
                    funnelRow(title: "分享数 (Share)", count: template.shareCount, max: max(1, template.viewCount), color: .green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("玩法数据")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func funnelRow(title: String, count: Int, max: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}
