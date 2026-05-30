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
            .confirmationDialog(
                "选择一个整活玩法",
                isPresented: $showCreateDialog,
                titleVisibility: .visible
            ) {
                ForEach(MockData.quickCreateTemplates) { tpl in
                    Button(tpl.name) {
                        createTemplate = tpl
                    }
                }
                Button("查看全部模板") {
                    selectedTab = 2
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("选好之后填写信息，点击「开始生成」即可产出图片。")
            }
            .sheet(item: $createTemplate) { tpl in
                NavigationStack {
                    GenerateFormView(template: tpl)
                        .navigationTitle(tpl.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("关闭") {
                                    createTemplate = nil
                                }
                                .foregroundColor(.themeTextMain)
                            }
                        }
                }
            }
        }
    }
}
