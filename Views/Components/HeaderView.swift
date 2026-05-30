import SwiftUI

struct HeaderView: View {
    @State private var isVip = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("整活局")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextMain)
                Image.bundle("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Button(action: {
                    isVip.toggle()
                }) {
                    Image.bundle("vip_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                        .grayscale(isVip ? 0.0 : 1.0)
                        .opacity(isVip ? 1.0 : 0.6)
                }
                
                Button(action: {
                    // Settings action
                }) {
                    Image.bundle("settings_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
