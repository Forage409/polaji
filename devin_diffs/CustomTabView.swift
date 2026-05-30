
+7
−6
import SwiftUI
 
struct CustomTabView: View {
    @Binding var selectedTab: Int
    var onCreateTap: () -> Void
    
    var body: some View {
        HStack {
            
            Spacer()
            
            // Create Button
            Button(action: {
                selectedTab = 2 // Redirects to templates for now
            }) {
            Button(action: onCreateTap) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.themePrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Image.bundle("tab_create")
                        .resizable()
                }
                .offset(y: -15)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
                    .foregroundColor(isSelected ? .themePrimary : .gray)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .themePrimary : .gray)
                    .font(.system(size: 10, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .themeTextMain : .themeTextSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

HeaderView.swift
