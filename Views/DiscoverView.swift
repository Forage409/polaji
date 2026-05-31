import SwiftUI
 
struct DiscoverView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerBar
                
                Picker("", selection: $selectedTab) {
                    Text("热门玩法").tag(0)
                    Text("玩家广场").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                TabView(selection: $selectedTab) {
                    TemplatesWaterfallView()
                        .tag(0)
                    
                    WorksFeedWaterfallView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        }
    }
    
    private var headerBar: some View {
        HStack {
            Text("发现")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

// MARK: - Templates Waterfall
struct TemplatesWaterfallView: View {
    @State private var templates: [Template] = MockData.allTemplates
    @State private var isLoading = false
    @State private var hasError = false
    
    let columns = [
        GridItem(.flexible(), spacing: 12, alignment: .top),
        GridItem(.flexible(), spacing: 12, alignment: .top)
    ]
    
    var body: some View {
        Group {
            if isLoading && templates.isEmpty {
                ProgressView("加载中...")
                    .padding(.top, 50)
            } else if templates.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暂无模板")
                        .foregroundColor(.themeTextSecondary)
                }
                .padding(.top, 80)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                TemplateWaterfallCard(template: template)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFeed"))) { _ in
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            do {
                let fetched = try await RemoteTemplateService.shared.fetchTemplates()
                await MainActor.run {
                    MockData.updateUsageCounts(from: fetched)
                    // Merge: keep local mocks, append any remote templates not already in MockData
                    let mockIds = Set(MockData.allTemplates.map { $0.id })
                    let extras = fetched
                        .filter { !mockIds.contains($0.id) }
                        .map { Template(from: $0) }
                    self.templates = MockData.allTemplates + extras
                }
            } catch {
                print("Failed to load real templates: \(error)")
                await MainActor.run {
                    self.templates = MockData.allTemplates
                }
            }
        }
    }
}

struct TemplateWaterfallCard: View {
    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                coverImageView
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)

                if template.category == "投票" {
                    Text("🔥 热门")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(8)
                }
            }

            Text(template.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(height: 36, alignment: .topLeading)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "FF6B8A"))
                Text("\(formatCount(template.usageCount)) 人生成")
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var coverImageView: some View {
        let raw = template.coverImage
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            CachedAsyncImage(url: RemoteImageURL.resolve(raw)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(ProgressView())
            }
        } else {
            Image.bundle(raw)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func formatCount(_ count: Int) -> String {
        return "\(count)"
    }
}

// MARK: - Works Waterfall
struct WorksFeedWaterfallView: View {
    @StateObject private var likeStore = LikedWorksStore.shared
    @State private var works: [PublicWork] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var hasMore = true
    @State private var errorMessage = ""
    
    let columns = [
        GridItem(.flexible(), spacing: 12, alignment: .top),
        GridItem(.flexible(), spacing: 12, alignment: .top)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading {
                ProgressView("加载中...")
                    .padding(.top, 50)
            } else if works.isEmpty, !errorMessage.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                    Button("重新加载") { loadWorks(reset: true) }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themePrimary)
                }
                .padding(.top, 80)
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
                        NavigationLink(destination: PublicWorkDetailView(work: work)) {
                            workFeedCard(work)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                if hasMore {
                    Button(action: { loadWorks(reset: false) }) {
                        if isLoadingMore {
                            ProgressView()
                        } else {
                            Text("加载更多")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themePrimary)
                        }
                    }
                    .disabled(isLoadingMore)
                    .padding(.vertical, 20)
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .padding(.bottom, 20)
                }
                Spacer(minLength: 100)
            }
        }
        .onAppear {
            loadWorks(reset: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshWorksFeed"))) { _ in
            loadWorks(reset: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PublicWorkLikeChanged"))) { note in
            guard let id = note.userInfo?["id"] as? String,
                  let likeCount = note.userInfo?["likeCount"] as? Int,
                  let index = works.firstIndex(where: { $0.id == id }) else { return }
            works[index].likeCount = likeCount
        }
    }

    private func loadWorks(reset: Bool) {
        if reset {
            isLoading = true
            errorMessage = ""
        } else {
            guard !isLoadingMore, hasMore else { return }
            isLoadingMore = true
        }
        Task {
            do {
                let offset = reset ? 0 : works.count
                let fetched = try await PublicWorksService.shared.fetchWorksFeed(offset: offset)
                await MainActor.run {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.errorMessage = ""
                    self.hasMore = fetched.count == 20
                    self.works = reset ? fetched : works + fetched.filter { newWork in
                        !works.contains { $0.id == newWork.id }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isLoadingMore = false
                    self.errorMessage = "加载失败，请检查网络后重试"
                }
                print("Failed to load works feed: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func workFeedCard(_ work: PublicWork) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            CachedAsyncImage(url: RemoteImageURL.resolve(work.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                    )
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
