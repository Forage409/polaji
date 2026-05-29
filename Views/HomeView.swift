import SwiftUI

struct HomeView: View {
    @StateObject private var store = WorksStore()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()
                
                MainBannerView()
                
                QuickActionsScrollView()
                
                HotTemplatesView(templates: MockData.hotTemplates)
                
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
        }
    }
}
