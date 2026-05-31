import SwiftUI

struct WorksFeedView: View {
    @StateObject private var likeStore = LikedWorksStore.shared
    @State private var works: [PublicWork] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 12, alignment: .top),
        GridItem(.flexible(), spacing: 12, alignment: .top)
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PublicWorkLikeChanged"))) { note in
                guard let id = note.userInfo?["id"] as? String,
                      let likeCount = note.userInfo?["likeCount"] as? Int,
                      let index = works.firstIndex(where: { $0.id == id }) else { return }
                works[index].likeCount = likeCount
            }
        }
    }
    
    private func loadWorks() {
        Task {
            do {
                let fetched = try await PublicWorksService.shared.fetchWorksFeed()
                await MainActor.run {
                    self.isLoading = false
                    self.works = fetched
                }
            } catch {
                await MainActor.run { self.isLoading = false }
                print("Failed to load works: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func workFeedCard(_ work: PublicWork) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: RemoteImageURL.resolve(work.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(work.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(height: 36, alignment: .topLeading)
            
            HStack {
                Text(work.isAnonymous ? "匿名用户" : work.authorName)
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: likeStore.isLiked(work.id) ? "heart.fill" : "heart")
                        .font(.system(size: 10))
                    Text("\(work.likeCount)")
                        .font(.system(size: 11))
                }
                .foregroundColor(likeStore.isLiked(work.id) ? .red : .themeTextSecondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
