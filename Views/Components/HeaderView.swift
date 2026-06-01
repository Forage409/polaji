import SwiftUI

struct HeaderView: View {
    var title: String = "整活局"
    var titleSuffix: String? = nil
    var showLogo: Bool = true
    
    @ObservedObject private var vip = VipManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.themeTextMain)
                
                if showLogo {
                    Image.bundle("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        }
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.themePrimary.opacity(0.55), lineWidth: 1))
                }
                
                if let suffix = titleSuffix {
                    Text(suffix)
                        .font(.system(size: 22))
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                NavigationLink(destination: PayWallView()) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(vip.isVip ? Color.themePrimary : Color.themePrimary.opacity(0.22))
                            .frame(width: 70, height: 32)
                        HStack(spacing: 4) {
                            Image.bundle("vip_icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .grayscale(vip.isVip ? 0.0 : 0.55)
                                .opacity(vip.isVip ? 1.0 : 0.85)
                            Text("VIP")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.themeTextMain)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: SettingsView()) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                        Image.bundle("settings_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}
