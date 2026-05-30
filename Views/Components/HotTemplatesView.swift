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
                        VStack(spacing: 8) {
                            Image.bundle(template.coverImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                            
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 10))
                                Text("\(String(format: "%.1f", Double(template.usageCount)/10000.0))w")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.themeTextSecondary)
                            }
                        }
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
