
+76
−58
import SwiftUI
 
struct ResultCardUI: View {
    let card: GeneratedCard
    var exportMode: Bool = false
    var showWatermark: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                backgroundForType()
        ZStack(alignment: .topLeading) {
            backgroundForType()
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.title)
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(headerTextColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(card.subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(headerTextColor.opacity(0.82))
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Image.bundle("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                
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
                
                // Footer
                HStack(spacing: 6) {
                    Text("内容仅供娱乐，切勿当真")
                        .font(.system(size: 10))
                        .foregroundColor(headerTextColor.opacity(0.5))
                    Spacer()
                    if showWatermark {
                        HStack(spacing: 3) {
                            Image.bundle("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                            Text("整活局")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(headerTextColor.opacity(0.55))
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
                    Text(card.createdAt)
                        .font(.system(size: 10))
                        .foregroundColor(headerTextColor.opacity(0.5))
                }
                .padding(24)
            }
            .padding(24)
        }
        .frame(width: 350, height: 520, alignment: .top)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .cornerRadius(exportMode ? 0 : 24)
        .shadow(color: exportMode ? .clear : .black.opacity(0.15), radius: exportMode ? 0 : 20, x: 0, y: exportMode ? 0 : 10)
    }
    
    // MARK: - Layouts

DiscoverView.swift
