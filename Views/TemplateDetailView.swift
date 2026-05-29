import SwiftUI

struct TemplateDetailView: View {
    let template: Template
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(template.coverImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipped()
                        .cornerRadius(16)
                        .padding()
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.themeTextMain)
                        
                        HStack {
                            Text(template.category)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.themePrimary.opacity(0.2))
                                .foregroundColor(.themeTextMain)
                                .cornerRadius(8)
                            
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("\(template.usageCount) 人已使用")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextSecondary)
                        }
                        
                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.themeTextSecondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            VStack {
                NavigationLink(destination: GenerateFormView(template: template)) {
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
    }
}
