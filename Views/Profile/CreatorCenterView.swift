import SwiftUI

struct CreatorCenterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main Stats Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总览大盘")
                                .font(.system(size: 18, weight: .bold))
                            Text("你的创作影响力")
                                .font(.system(size: 12))
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 20) {
                        statItem(title: "已发布", value: "12")
                        statItem(title: "总浏览", value: "3.2k")
                        statItem(title: "总生成", value: "1.5k")
                    }
                    
                    HStack(spacing: 20) {
                        statItem(title: "总分享", value: "480")
                        statItem(title: "总点赞", value: "2.1k")
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Actions
                VStack(spacing: 0) {
                    NavigationLink(destination: MyPublishedTemplatesView()) {
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.themePrimary)
                                .frame(width: 24)
                            Text("我发布的玩法")
                                .font(.system(size: 16))
                                .foregroundColor(.themeTextMain)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white)
                    }
                }
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("创作者中心")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.themeTextMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
