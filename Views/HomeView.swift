import SwiftUI

struct HomeView: View {
    @StateObject private var store = WorksStore()
    @StateObject private var catalog = TemplateCatalogStore.shared
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()
                
                MainBannerView(template: MockData.allTemplates[0])
                
                QuickActionsScrollView()
                
                HotTemplatesView(templates: catalog.featuredTemplates)
                
                if !store.works.isEmpty {
                    RecentWorksView(works: store.works)
                } else {
                    RecentWorksView(works: MockData.recentWorks)
                }
                
                Spacer().frame(height: 80)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            store.refresh()
            Task { await catalog.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppEvents.templatesChanged)) { _ in
            Task { await catalog.refresh() }
        }
    }
}
