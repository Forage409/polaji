import SwiftUI

struct HotTemplatesView: View {
    let templates: [Template]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("热门模板")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextMain)
                
                Spacer()
                
                Text("更多 >")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(templates) { template in
                    NavigationLink(destination: TemplateDetailView(template: template)) {
                        VStack(alignment: .leading, spacing: 0) {
                            Image.bundle(template.coverImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.themeTextMain)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer(minLength: 0)
                                
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.themePrimary)
                                        .font(.system(size: 10))
                                    Text("\(String(format: "%.1f", Double(template.usageCount)/10000.0))w 人生成")
                                        .font(.system(size: 10))
                                        .foregroundColor(.themeTextSecondary)
                                }
                            }
                            .padding(12)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
