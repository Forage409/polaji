import SwiftUI

struct HomeView: View {
    @StateObject private var store = WorksStore()
    @State private var hotTemplates: [Template] = []
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()
                
                if let firstHot = hotTemplates.first {
                    MainBannerView(template: firstHot)
                }
                
                QuickActionsScrollView(templates: hotTemplates)
                
                if !hotTemplates.isEmpty {
                    HotTemplatesView(templates: hotTemplates)
                }
                
                RecentWorksView(works: store.works)
                
                Spacer().frame(height: 80)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            store.refresh()
            if hotTemplates.isEmpty {
                Task {
                    do {
                        let fetched = try await RemoteTemplateService.shared.fetchFeaturedTemplates()
                        await MainActor.run {
                            self.hotTemplates = fetched.map { rt in
                                Template(
                                    id: rt.id,
                                    name: rt.title,
                                    category: rt.category,
                                    description: rt.description,
                                    coverImage: rt.coverImage,
                                    isVip: false,
                                    usageCount: rt.usageCount,
                                    tags: [],
                                    fields: []
                                )
                            }
                        }
                    } catch {
                        print("Failed to fetch featured templates: \(error)")
                    }
                }
            }
        }
    }
}
