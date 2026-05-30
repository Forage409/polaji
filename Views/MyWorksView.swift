import SwiftUI
 
struct MyWorksView: View {
    @ObservedObject private var store = WorksStore.shared
    @ObservedObject private var profile = UserProfileStore.shared
    @State private var selectedCategory = "全部"
    @State private var searchKeyword: String = ""
    @State private var showSearch = false
    @Environment(\.presentationMode) var presentationMode
    
    private let categories = ["全部", "人设卡", "判官", "投票", "趣味", "其他"]
    
    private var filteredWorks: [Work] {
        var w = store.works
        if selectedCategory != "全部" {
            if selectedCategory == "其他" {
                w = w.filter { !["人设卡", "判官", "投票", "趣味"].contains($0.category) }
            } else {
                w = w.filter { $0.category == selectedCategory }
            }
        }
        if !searchKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
            let kw = searchKeyword.lowercased()
            w = w.filter { $0.title.lowercased().contains(kw) }
        }
        return w
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if showSearch {
                searchField
            }
            categoryStrip
            
            if filteredWorks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(filteredWorks) { work in
                            WorkCardCell(work: work) {
                                store.deleteWork(id: work.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Text("已经到底啦 ~")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .padding(.vertical, 24)
                }
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
    
    private var headerBar: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.themeTextMain)
            }
            Text("我的作品")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Spacer()
            Button(action: { withAnimation { showSearch.toggle() } }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                }
            }
            NavigationLink(destination: SettingsView()) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                    Image.bundle("settings_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.themeTextSecondary)
            TextField("搜索作品标题", text: $searchKeyword)
                .font(.system(size: 14))
            if !searchKeyword.isEmpty {
                Button(action: { searchKeyword = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
    
    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { c in
                    Text(c)
                        .font(.system(size: 13, weight: selectedCategory == c ? .bold : .medium))
                        .foregroundColor(selectedCategory == c ? .themeTextMain : .themeTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == c ? Color.themePrimary : Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedCategory == c ? Color.themePrimary : Color.gray.opacity(0.12), lineWidth: 1)
                        )
                        .onTapGesture {
                            withAnimation { selectedCategory = c }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .padding(.bottom, 6)
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "B58900"))
            }
            Text(searchKeyword.isEmpty ? "还没有作品" : "没有匹配的作品")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Text(searchKeyword.isEmpty ? "去模板页选一个玩法，整一张专属卡片吧" : "试试其他关键词")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
 
struct WorkCardCell: View {
    let work: Work
    let onDelete: () -> Void
    
    @State private var showActions = false
    @State private var showShareAlert = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationLink(destination: WorkDetailView(work: work)) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        if let uiImage = loadImage() {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } else {
                            Image.bundle(coverPlaceholder())
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        }
                        
                        Text(work.category)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.45))
                            .cornerRadius(10)
                            .padding(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(work.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeTextMain)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(.themeTextSecondary)
                            Text(work.createdAt)
                                .font(.system(size: 11))
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                    .padding(12)
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                Button(action: { showActions = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.themeTextMain)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .offset(x: 0, y: 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("作品操作", isPresented: $showActions, titleVisibility: .hidden) {
            Button("保存图片", action: saveImage)
            Button("再次分享", action: shareImage)
            Button("删除作品", role: .destructive, action: onDelete)
            Button("取消", role: .cancel) {}
        }
        .toast(isPresented: $showAlert, message: alertMessage)
    }
    
    private func loadImage() -> UIImage? {
        return ImageExportManager.shared.loadImage(from: work.imagePath)
    }
    
    private func coverPlaceholder() -> String {
        return "cover_persona" // Fallback since we can't synchronously load remote template here without state
    }
    
    private func saveImage() {
        guard let img = loadImage() else {
            alertMessage = "原始图片已丢失，无法保存"
            showAlert = true
            return
        }
        ImageExportManager.shared.saveImageToPhotos(img) { success in
            alertMessage = success ? "已保存到系统相册！" : "保存失败，请检查相册权限"
            showAlert = true
        }
    }
    
    private func shareImage() {
        guard let img = loadImage() else {
            alertMessage = "原始图片已丢失，无法分享"
            showAlert = true
            return
        }
        ImageExportManager.shared.shareImage(img)
    }
}
