import SwiftUI

struct HomeView: View {
    @StateObject private var store = WorksStore()
    @State private var hotTemplates: [Template] = MockData.hotTemplates
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()
                
                MainBannerView(template: MockData.allTemplates[0])
                
                QuickActionsScrollView()
                
                HotTemplatesView(templates: hotTemplates)
                
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
            Task {
                do {
                    let fetched = try await RemoteTemplateService.shared.fetchFeaturedTemplates()
                    await MainActor.run {
                        MockData.updateUsageCounts(from: fetched)
                        self.hotTemplates = MockData.hotTemplates
                    }
                } catch {
                    print("Failed to fetch featured templates: \(error)")
                }
            }
        }
    }
}
