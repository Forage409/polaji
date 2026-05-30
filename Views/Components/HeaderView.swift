import SwiftUI

struct HeaderView: View {
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
            
            HStack(spacing: 12) {
                Image.bundle("vip_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                
                Image.bundle("settings_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
