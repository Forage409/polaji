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
                                .scaledToFill()
                                .frame(height: 120)
                                .clipped()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.themeTextMain)
                                    .lineLimit(1)
                                
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 10))
                                    Text("\(template.usageCount/1000)k人使用")
                                        .font(.system(size: 10))
                                        .foregroundColor(.themeTextSecondary)
                                }
                            }
                            .padding(10)
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
