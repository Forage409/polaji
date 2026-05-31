import SwiftUI

struct MyPublishedTemplatesView: View {
    enum ViewState {
        case loading
        case loaded([RemoteTemplate])
        case empty
        case error(String)
    }
    
    @State private var state: ViewState = .loading
    @State private var actionError = ""
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("加载数据中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let templates):
                contentView(templates: templates)
            case .empty:
                emptyView
            case .error(let msg):
                errorView(message: msg)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("我的发布")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    loadData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.themeTextMain)
                }
            }
        }
        .onAppear {
            if case .loading = state {
                loadData()
            }
        }
        .alert("操作失败", isPresented: Binding(
            get: { !actionError.isEmpty },
            set: { if !$0 { actionError = "" } }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(actionError)
        }
    }
    
    private func loadData() {
        state = .loading
        Task {
            do {
                let templates = try await RemoteCreatorService.shared.fetchMyPublishedTemplates()
                DispatchQueue.main.async {
                    if templates.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(templates)
                    }
                }
            } catch let error as APIError {
                DispatchQueue.main.async {
                    self.state = .error(error.localizedDescription)
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    @ViewBuilder
    private func contentView(templates: [RemoteTemplate]) -> some View {
        ScrollView {
            if #available(iOS 15.0, *) {
                Color.clear.frame(height: 0)
                    .refreshable {
                        loadData()
                    }
            }
            VStack(spacing: 16) {
                ForEach(templates) { template in
                    HStack(spacing: 0) {
                        NavigationLink(destination: TemplateStatsView(template: template)) {
                            publishedTemplateCard(template)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Menu {
                            Button {
                                updateStatus(template, status: template.status == "published" ? "hidden" : "published")
                            } label: {
                                Label(template.status == "published" ? "隐藏玩法" : "重新发布", systemImage: template.status == "published" ? "eye.slash" : "eye")
                            }
                            Button(role: .destructive) {
                                delete(template)
                            } label: {
                                Label("删除玩法", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.themeTextSecondary)
                                .padding(.horizontal, 12)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
            .padding()
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无发布的玩法")
                .font(.system(size: 16))
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.octagon")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.6))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: {
                loadData()
            }) {
                Text("点击重试")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary.opacity(0.1))
                    .cornerRadius(18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func publishedTemplateCard(_ template: RemoteTemplate) -> some View {
        HStack(spacing: 12) {
            coverThumb(for: template.coverImage)
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(template.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text("状态: \(template.status == "published" ? "已发布" : "已隐藏")")
                    .font(.system(size: 12))
                    .foregroundColor(.themePrimary)

                Spacer()

                HStack(spacing: 16) {
                    statMini(icon: "eye", val: template.viewCount)
                    statMini(icon: "wand.and.stars", val: template.generateCount)
                    statMini(icon: "square.and.arrow.up", val: template.shareCount)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }

    private func updateStatus(_ template: RemoteTemplate, status: String) {
        Task {
            do {
                _ = try await RemoteCreatorService.shared.updateTemplateStatus(templateId: template.id, status: status)
                await MainActor.run { loadData() }
            } catch {
                await MainActor.run { actionError = error.localizedDescription }
            }
        }
    }

    private func delete(_ template: RemoteTemplate) {
        Task {
            do {
                _ = try await RemoteCreatorService.shared.deleteTemplate(templateId: template.id)
                await MainActor.run { loadData() }
            } catch {
                await MainActor.run { actionError = error.localizedDescription }
            }
        }
    }

    @ViewBuilder
    private func coverThumb(for raw: String) -> some View {
        if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
            CachedAsyncImage(url: RemoteImageURL.resolve(raw)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(ProgressView().scaleEffect(0.7))
            }
        } else if !raw.isEmpty, UIImage(named: raw) != nil {
            Image.bundle(raw)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    Text("无封面")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                )
        }
    }
    
    private func statMini(icon: String, val: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(val)")
                .font(.system(size: 12))
        }
        .foregroundColor(.themeTextSecondary)
    }
}

struct TemplateStatsView: View {
    let template: RemoteTemplate
    
    enum ViewState {
        case loading
        case loaded(TemplateStats)
        case error(String)
    }
    
    @State private var state: ViewState = .loading
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("拉取数据中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let stats):
                statsContentView(stats: stats)
            case .error(let msg):
                VStack(spacing: 16) {
                    Text(msg)
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("重试") {
                        loadStats()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("玩法数据")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if case .loading = state {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        state = .loading
        Task {
            do {
                let stats = try await RemoteCreatorService.shared.fetchTemplateStats(templateId: template.id)
                DispatchQueue.main.async {
                    self.state = .loaded(stats)
                }
            } catch let error as APIError {
                DispatchQueue.main.async {
                    self.state = .error(error.localizedDescription)
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    @ViewBuilder
    private func statsContentView(stats: TemplateStats) -> some View {
        ScrollView {
            if #available(iOS 15.0, *) {
                Color.clear.frame(height: 0)
                    .refreshable {
                        loadStats()
                    }
            }
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.title)
                        .font(.system(size: 20, weight: .bold))
                    Text("发布于 \(template.createdAt)")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("数据漏斗")
                        .font(.system(size: 16, weight: .bold))
                    
                    let maxVal = max(1, stats.viewCount)
                    funnelRow(title: "浏览数 (View)", count: stats.viewCount, max: maxVal, color: .purple)
                    funnelRow(title: "点击开始 (Start)", count: stats.startCount, max: maxVal, color: .blue)
                    funnelRow(title: "成功生成 (Generate)", count: stats.generateCount, max: maxVal, color: .orange)
                    funnelRow(title: "分享数 (Share)", count: stats.shareCount, max: maxVal, color: .green)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding()
        }
    }
    
    private func funnelRow(title: String, count: Int, max: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(max))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}
