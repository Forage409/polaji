import SwiftUI

struct TemplateDetailView: View {
    let template: Template
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        Image.bundle(template.coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 360)
                            .clipped()
                        
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(template.category)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.themePrimary)
                                    .foregroundColor(.themeTextMain)
                                    .cornerRadius(6)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                    Text("\(template.usageCount) 人已生成")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            }
                            
                            Text(template.name)
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .padding(20)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("模板介绍")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.themeTextMain)
                        
                        Text(template.description)
                            .font(.system(size: 15))
                            .foregroundColor(.themeTextSecondary)
                            .lineSpacing(6)
                        
                        // WeChat moments style preview
                        if template.category != "未知" {
                            Image.bundle(template.coverImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeBackground)
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            VStack {
                NavigationLink(destination: GenerateFormView(template: template).onAppear {
                    Task {
                        try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_start")
                    }
                }) {
                    Text("立即生成")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.themePrimary)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30) // Fixed safeAreaInsets deprecation
            }
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            BrowseHistoryStore.shared.record(template: template)
            Task {
                try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_view")
            }
        }
    }
}
