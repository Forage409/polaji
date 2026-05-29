import SwiftUI

struct RecentWorksView: View {
    let works: [Work]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近生成")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextMain)
                
                Spacer()
                
                Text("全部 >")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(works) { work in
                        VStack {
                            ZStack {
                                Color.white
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                
                                VStack(spacing: 0) {
                                    ZStack {
                                        Color(hex: "F0F4FF")
                                        VStack {
                                            Text(work.category)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.white.opacity(0.8))
                                                .cornerRadius(4)
                                                .padding(6)
                                            Spacer()
                                        }
                                        
                                        if work.imagePath.starts(with: "/") || work.imagePath.starts(with: "file://") {
                                            if let uiImage = UIImage(contentsOfFile: work.imagePath) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(15)
                                            } else {
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .padding(15)
                                                    .foregroundColor(.gray)
                                            }
                                        } else {
                                            Image(work.imagePath.replacingOccurrences(of: ".png", with: ""))
                                                .resizable()
                                                .scaledToFit()
                                                .padding(15)
                                        }
                                    }
                                    .frame(height: 120)
                                    .cornerRadius(10, corners: [.topLeft, .topRight])
                                    
                                    HStack {
                                        Text(work.createdAt)
                                            .font(.system(size: 11))
                                            .foregroundColor(.themeTextSecondary)
                                        Spacer()
                                        Image(systemName: "ellipsis")
                                            .foregroundColor(.themeTextSecondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                }
                            }
                            .frame(width: 120, height: 160)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
