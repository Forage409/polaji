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
                        ZStack(alignment: .bottomLeading) {
                            Image.bundle(template.coverImage)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fit)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.themePrimary)
                                    .font(.system(size: 10))
                                Text("\(String(format: "%.1f", Double(template.usageCount)/10000.0))w")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Capsule())
                            .padding(8)
                        }
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
