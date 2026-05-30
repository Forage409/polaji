import SwiftUI

struct MainBannerView: View {
    var body: some View {
        NavigationLink(destination: TemplateDetailView(template: MockData.allTemplates.first(where: { $0.id == "persona_card" }) ?? MockData.allTemplates[0])) {
            ZStack(alignment: .leading) {
                Image.bundle("banner_bg_decorations")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
                
                Color.themePrimary.opacity(0.1) // Fallback if bg image is missing or to tint
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日摸鱼人设卡")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.themeTextMain)
                        
                        Text("立刻生成，发圈必备！")
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                        
                        Text("去生成 >")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.themePrimary)
                            .foregroundColor(.themeTextMain)
                            .cornerRadius(12)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Image.bundle("banner_character")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.trailing, 10)
                        .offset(y: 10)
                }
            }
            .frame(height: 140)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal)
            .shadow(color: Color.themePrimary.opacity(0.3), radius: 15, x: 0, y: 5)
        }
    }
}
