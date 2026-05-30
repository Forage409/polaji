import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showCreateDialog = false
    @State private var createTemplate: Template?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                    
                    DiscoverView()
                        .tag(1)
                    
                    TemplatesView()
                        .tag(2)
                    
                    ProfileView()
                        .tag(3)
                }
                .onAppear {
                    UITabBar.appearance().isHidden = true
                }
                
                CustomTabView(selectedTab: $selectedTab, onCreateTap: {
                    showCreateDialog = true
                })
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showCreateDialog) {
                TemplateEditorView()
            }
        }
    }
}
