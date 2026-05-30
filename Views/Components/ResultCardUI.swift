import SwiftUI

struct ResultCardUI: View {
    let card: GeneratedCard
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "EFE7FF"), Color(hex: "FFF9E6")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.themeTextMain)
                            Text(card.subtitle)
                                .font(.system(size: 14))
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                        Image.bundle("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(card.stats) { stat in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(stat.name)
                                            .font(.system(size: 12, weight: .bold))
                                        Spacer()
                                        Text("\(stat.value)%")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.5))
                                                .frame(height: 8)
                                                .cornerRadius(4)
                                            
                                            Rectangle()
                                                .fill(Color.themePrimary)
                                                .frame(width: geometry.size.width * CGFloat(stat.value) / 100, height: 8)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Image.bundle(card.mainImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    }
                    .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日宣言：")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                        Text(card.quote)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themeTextMain)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    HStack {
                        Text("整活局生成")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(card.createdAt)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 350, height: 500)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}
