import SwiftUI

struct CreatorCenterView: View {
    enum ViewState {
        case loading
        case loaded(CreatorDashboard)
        case empty
        case error(String)
    }
    
    @State private var state: ViewState = .loading
    @State private var showEditor = false
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("加载数据中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let dashboard):
                contentView(dashboard: dashboard)
            case .empty:
                emptyView
            case .error(let msg):
                errorView(message: msg)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("创作者中心")
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
        .fullScreenCover(isPresented: $showEditor) {
            TemplateEditorView()
        }
    }
    
    private func loadData() {
        state = .loading
        Task {
            do {
                let dashboard = try await RemoteCreatorService.shared.fetchCreatorDashboard()
                DispatchQueue.main.async {
                    if dashboard.publishedCount == 0 {
                        self.state = .empty
                    } else {
                        self.state = .loaded(dashboard)
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
    private func contentView(dashboard: CreatorDashboard) -> some View {
        ScrollView {
            // Added pull to refresh for iOS 15+ 
            if #available(iOS 15.0, *) {
                Color.clear.frame(height: 0) // Placeholder
                    .refreshable {
                        loadData()
                    }
            }
            
            VStack(spacing: 20) {
                // Main Stats Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总览大盘")
                                .font(.system(size: 18, weight: .bold))
                            Text("你的创作影响力")
                                .font(.system(size: 12))
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 20) {
                        statItem(title: "已发布", value: "\(dashboard.publishedCount)")
                        statItem(title: "总浏览", value: "\(dashboard.totalViewCount)")
                        statItem(title: "总生成", value: "\(dashboard.totalGenerateCount)")
                    }
                    
                    HStack(spacing: 20) {
                        statItem(title: "总分享", value: "\(dashboard.totalShareCount)")
                        statItem(title: "总点赞", value: "\(dashboard.totalLikeCount)")
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Actions
                VStack(spacing: 0) {
                    Button(action: {
                        showEditor = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.themePrimary)
                                .frame(width: 24)
                            Text("发布新玩法")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.themeTextMain)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white)
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.08))
                        .frame(height: 1)
                        .padding(.leading, 56)
                    
                    NavigationLink(destination: MyPublishedTemplatesView()) {
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.themePrimary)
                                .frame(width: 24)
                            Text("我发布的玩法")
                                .font(.system(size: 16))
                                .foregroundColor(.themeTextMain)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white)
                    }
                }
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("你还没有发布任何玩法")
                .font(.system(size: 16))
                .foregroundColor(.themeTextSecondary)
            
            Button(action: {
                showEditor = true
            }) {
                Text("立即发布")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .frame(width: 160, height: 44)
                    .background(Color.themePrimary)
                    .cornerRadius(22)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
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
    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.themeTextMain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
