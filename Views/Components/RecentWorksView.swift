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
            
            if works.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("还没有生成作品，去生成第一张整活卡吧")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(works) { work in
                            NavigationLink(destination: WorkDetailView(work: work)) {
                                VStack(spacing: 0) {
                                    ZStack {
                                        Color(hex: "F0F4FF")
                                        VStack {
                                            HStack {
                                                Text(work.category)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.white.opacity(0.8))
                                                    .cornerRadius(4)
                                                Spacer()
                                            }
                                            .padding(6)
                                            Spacer()
                                        }
                                        
                                        if let uiImage = ImageExportManager.shared.loadImage(from: work.imagePath) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipped()
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(15)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
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
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .frame(width: 120, height: 160)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
