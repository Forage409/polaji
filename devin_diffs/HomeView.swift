
+20
−18
import SwiftUI
 
struct HomeView: View {
    @StateObject private var store = WorksStore()
    @ObservedObject private var store = WorksStore.shared
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()
                
                MainBannerView()
                
                QuickActionsScrollView()
                
                HotTemplatesView(templates: MockData.hotTemplates)
                
                RecentWorksView(works: store.works)
                
                Spacer().frame(height: 80)
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HeaderView()
                    
                    MainBannerView()
                    
                    QuickActionsScrollView()
                    
                    HotTemplatesView(templates: MockData.hotTemplates)
                    
                    RecentWorksView(works: store.works)
                    
                    Spacer().frame(height: 80)
                }
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
            .onAppear {
                store.refresh()
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .onAppear {
            store.refresh()
        }
    }
}

MyWorksView.swift
