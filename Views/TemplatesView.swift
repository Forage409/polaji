import SwiftUI

struct TemplatesView: View {
    @State private var selectedCategory = "全部"
    let categories = ["全部", "人设卡", "判官", "投票", "趣味"]
    @StateObject private var catalog = TemplateCatalogStore.shared
    private let cardWidth = LayoutMetrics.twoColumnCardWidth(horizontalPadding: 16, spacing: 16)
    
    var filteredTemplates: [Template] {
        if selectedCategory == "全部" {
            return catalog.templates
        } else {
            return catalog.templates.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(categories, id: \.self) { category in
                            VStack(spacing: 6) {
                                Text(category)
                                    .font(.system(size: 16, weight: selectedCategory == category ? .bold : .medium))
                                    .foregroundColor(selectedCategory == category ? .themeTextMain : .themeTextSecondary)
                                
                                Rectangle()
                                    .fill(selectedCategory == category ? Color.themePrimary : Color.clear)
                                    .frame(width: 20, height: 3)
                                    .cornerRadius(1.5)
                            }
                            .onTapGesture {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 10)
                
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(cardWidth), spacing: 16, alignment: .top),
                            GridItem(.fixed(cardWidth), spacing: 16, alignment: .top)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredTemplates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                ZStack(alignment: .bottomLeading) {
                                    templateCover(template)
                                        .aspectRatio(3/4, contentMode: .fit)
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
                    .padding()
                }
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("所有模板")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { await catalog.refresh() }
            }
            .onReceive(NotificationCenter.default.publisher(for: AppEvents.templatesChanged)) { _ in
                Task { await catalog.refresh() }
            }
        }
    }

    @ViewBuilder
    private func templateCover(_ template: Template) -> some View {
        if template.coverImage.hasPrefix("http://") || template.coverImage.hasPrefix("https://") {
            CachedAsyncImage(url: RemoteImageURL.resolve(template.coverImage)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Color.gray.opacity(0.14)
            }
        } else {
            Image.bundle(template.coverImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
