import SwiftUI

struct CustomTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(imageName: "tab_home", title: "首页", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            Spacer()
            
            TabBarButton(imageName: "tab_discover", title: "发现", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            Spacer()
            
            // Create Button
            Button(action: {
                selectedTab = 2 // Redirects to templates for now
            }) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary)
                        .frame(width: 56, height: 56)
                    
                    Image.bundle("tab_create")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .offset(y: -15)
            }
            
            Spacer()
            
            TabBarButton(imageName: "tab_templates", title: "模板", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            Spacer()
            
            TabBarButton(imageName: "tab_profile", title: "我的", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
    }
}

struct TabBarButton: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image.bundle(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .themePrimary : .gray)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .themePrimary : .gray)
            }
        }
    }
}
