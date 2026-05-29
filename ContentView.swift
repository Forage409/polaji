import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(0)
                    
                    Text("发现页")
                        .tag(1)
                    
                    TemplatesView()
                        .tag(2)
                    
                    Text("我的")
                        .tag(3)
                }
                .onAppear {
                    UITabBar.appearance().isHidden = true
                }
                
                CustomTabView(selectedTab: $selectedTab)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}
