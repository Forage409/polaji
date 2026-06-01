import SwiftUI

struct HotTemplatesView: View {
    let templates: [Template]
    private let cardWidth = LayoutMetrics.twoColumnCardWidth(horizontalPadding: 16, spacing: 16)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("热门模板")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextMain)
                
                Spacer()
                
                NavigationLink(destination: DiscoverView()) {
                    Text("更多 >")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(
                columns: [
                    GridItem(.fixed(cardWidth), spacing: 16, alignment: .top),
                    GridItem(.fixed(cardWidth), spacing: 16, alignment: .top)
                ],
                spacing: 16
            ) {
                ForEach(templates) { template in
                    NavigationLink(destination: TemplateDetailView(template: template)) {
                        ZStack(alignment: .bottomLeading) {
                            coverImage(for: template)
                                .aspectRatio(3/4, contentMode: .fill)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.themePrimary)
                                    .font(.system(size: 10))
                                Text("\(template.usageCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Capsule())
                            .padding(8)
                        }
                        .frame(width: cardWidth)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func coverImage(for template: Template) -> some View {
        if template.coverImage.hasPrefix("http://") || template.coverImage.hasPrefix("https://") {
            CachedAsyncImage(url: RemoteImageURL.resolve(template.coverImage)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.14)
            }
            .clipped()
        } else {
            Image.bundle(template.coverImage)
                .resizable()
                .scaledToFill()
                .clipped()
        }
    }
}
