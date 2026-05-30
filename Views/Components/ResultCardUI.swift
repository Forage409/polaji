import SwiftUI

struct ResultCardUI: View {
    let card: GeneratedCard
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                backgroundForType()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.title)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(headerTextColor)
                            Text(card.subtitle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(headerTextColor.opacity(0.8))
                        }
                        Spacer()
                        Image.bundle("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    
                    // Main Content Area based on Type
                    if card.templateType == "rank" {
                        rankLayout()
                    } else if card.templateType == "verdict" {
                        verdictLayout()
                    } else if card.templateType == "task" {
                        taskLayout()
                    } else {
                        diagnosticLayout()
                    }
                    
                    Spacer(minLength: 10)
                    
                    // Quote
                    if !card.quote.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.templateType == "task" ? "任务提示：" : (card.templateType == "verdict" ? "法官寄语：" : "今日宣言："))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(headerTextColor.opacity(0.8))
                            Text(card.quote)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(headerTextColor)
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Footer
                    HStack {
                        Text("内容仅供娱乐，切勿当真")
                            .font(.system(size: 10))
                            .foregroundColor(headerTextColor.opacity(0.5))
                        Spacer()
                        Text(card.createdAt)
                            .font(.system(size: 10))
                            .foregroundColor(headerTextColor.opacity(0.5))
                    }
                }
                .padding(24)
            }
        }
        .frame(width: 350, height: 520) // slightly taller to fit evidence
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Layouts
    
    @ViewBuilder
    private func diagnosticLayout() -> some View {
        VStack(spacing: 16) {
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
                            .foregroundColor(headerTextColor)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.4))
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
                    .frame(width: 110, height: 110)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.evidenceList, id: \.self) { evidence in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.themePrimary)
                            .font(.system(size: 14))
                        Text(evidence)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(headerTextColor.opacity(0.9))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.3))
            .cornerRadius(12)
            
            VStack(spacing: 6) {
                Text(card.resultLevel)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.themePrimary)
                Text(card.finalComment)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(headerTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private func rankLayout() -> some View {
        VStack(spacing: 16) {
            Image.bundle(card.mainImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
            
            VStack(spacing: 10) {
                ForEach(Array(card.evidenceList.enumerated()), id: \.offset) { index, rankStr in
                    HStack {
                        if index == 0 {
                            Image(systemName: "crown.fill").foregroundColor(.yellow)
                        } else if index == 1 {
                            Image(systemName: "medal.fill").foregroundColor(.gray)
                        } else if index == 2 {
                            Image(systemName: "medal.fill").foregroundColor(.brown)
                        }
                        
                        Text(rankStr)
                            .font(.system(size: index == 0 ? 16 : 14, weight: index == 0 ? .bold : .medium))
                            .foregroundColor(headerTextColor)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(index == 0 ? Color.themePrimary.opacity(0.8) : Color.white.opacity(0.5))
                    .cornerRadius(12)
                }
            }
            
            Text(card.finalComment)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.8))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func verdictLayout() -> some View {
        VStack(spacing: 12) {
            HStack {
                Image.bundle(card.mainImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("判决等级")
                        .font(.system(size: 12))
                        .foregroundColor(headerTextColor.opacity(0.8))
                    Text(card.resultLevel)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("【案情陈述】")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(headerTextColor)
                ForEach(card.evidenceList, id: \.self) { evidence in
                    Text("• " + evidence)
                        .font(.system(size: 13))
                        .foregroundColor(headerTextColor.opacity(0.9))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.4))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("【最终判决】")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(card.finalComment)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                Image(systemName: "seal.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.red.opacity(0.4))
                    .rotationEffect(.degrees(15))
                    .padding(10)
                , alignment: .bottomTrailing
            )
        }
    }
    
    @ViewBuilder
    private func taskLayout() -> some View {
        VStack(spacing: 20) {
            Image.bundle(card.mainImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(card.evidenceList, id: \.self) { evidence in
                    Text(evidence)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(headerTextColor)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
            
            Text(card.resultLevel)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Styles
    
    private var headerTextColor: Color {
        if card.templateType == "verdict" { return Color(hex: "333333") }
        if card.templateType == "rank" { return Color(hex: "222222") }
        return Color(hex: "111111")
    }
    
    @ViewBuilder
    private func backgroundForType() -> some View {
        if card.templateType == "verdict" {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "FFF0F0"), Color(hex: "FFE4E1")]), startPoint: .top, endPoint: .bottom)
        } else if card.templateType == "rank" {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "F0F8FF"), Color(hex: "E6E6FA")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if card.templateType == "task" {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "FFF5EE"), Color(hex: "FFE4B5")]), startPoint: .top, endPoint: .bottom)
        } else {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "EFE7FF"), Color(hex: "FFF9E6")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
