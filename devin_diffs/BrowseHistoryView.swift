import SwiftUI
 
struct BrowseHistoryView: View {
    @ObservedObject private var store = BrowseHistoryStore.shared
    @State private var showClearAlert = false
    
    var body: some View {
        Group {
            if store.entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.entries) { entry in
                        if let template = MockData.template(id: entry.templateId) {
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                row(entry: entry)
                            }
                            .listRowBackground(Color.themeBackground)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        } else {
                            row(entry: entry)
                                .listRowBackground(Color.themeBackground)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            store.remove(id: store.entries[idx].id)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.themeBackground)
            }
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("浏览历史")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !store.entries.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空") { showClearAlert = true }
                        .foregroundColor(.themeTextMain)
                }
            }
        }
        .alert("清空浏览历史？", isPresented: $showClearAlert) {
            Button("清空", role: .destructive) { store.clear() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可撤销，但不影响你已生成的作品。")
        }
    }
    
    private func row(entry: BrowseHistoryEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 64, height: 64)
                Image.bundle(entry.coverImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.templateName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .lineLimit(1)
                Text(entry.category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "7B61FF"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "7B61FF").opacity(0.12))
                    .cornerRadius(8)
                Text(relativeTime(entry.visitedAt))
                    .font(.system(size: 11))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.themeSuccessGreen.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(Color.themeSuccessGreen)
            }
            Text("还没有浏览记录")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.themeTextMain)
            Text("打开任意模板即可在这里看到浏览历史。")
                .font(.system(size: 13))
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 80)
        .frame(maxWidth: .infinity)
    }
    
    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60)) 分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600)) 小时前" }
        if Calendar.current.isDateInYesterday(date) {
            let f = DateFormatter()
            f.dateFormat = "昨天 HH:mm"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: date)
    }
}

EditProfileView.swift
