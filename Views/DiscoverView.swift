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
    @State private var templates: [Template] = []
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
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
        .onAppear {
            RemoteTemplateService.shared.fetchTemplates { fetched in
                if let fetched = fetched, !fetched.isEmpty {
                    self.templates = fetched
                } else {
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
                Image.bundle(template.coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 200) // Fixed height or dynamic, usually Pinterest style has dynamic, but fixed is safer for UI
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        }
        return "\(count)"
    }
}

// MARK: - Works Waterfall
struct WorksFeedWaterfallView: View {
    @State private var works: [PublicWork] = []
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            PublicWorksService.shared.fetchWorksFeed { result in
                isLoading = false
                if let fetched = result {
                    self.works = fetched
                }
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
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                    )
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
