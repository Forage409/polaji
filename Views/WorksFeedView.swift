import SwiftUI

struct WorksFeedView: View {
    @State private var works: [PublicWork] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("加载中...")
                        .padding(.top, 50)
                } else if works.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("暂无广场作品")
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(works) { work in
                            workFeedCard(work)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("作品广场")
            .onAppear(perform: loadWorks)
        }
    }
    
    private func loadWorks() {
        PublicWorksService.shared.fetchWorksFeed { result in
            isLoading = false
            if let fetched = result {
                self.works = fetched
            }
        }
    }
    
    @ViewBuilder
    private func workFeedCard(_ work: PublicWork) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: work.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(12)
            }
            
            Text(work.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
                .lineLimit(2)
            
            HStack {
                Text(work.isAnonymous ? "匿名用户" : work.authorName)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: "heart")
                        .font(.system(size: 10))
                    Text("\(work.likeCount)")
                        .font(.system(size: 11))
                }
                .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
