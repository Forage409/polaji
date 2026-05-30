import SwiftUI

struct TemplatesView: View {
    @State private var selectedCategory = "全部"
    let categories = ["全部", "人设卡", "判官", "投票", "趣味"]
    
    var filteredTemplates: [Template] {
        if selectedCategory == "全部" {
            return MockData.allTemplates
        } else {
            return MockData.allTemplates.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(categories, id: \.self) { category in
                            VStack(spacing: 6) {
                                Text(category)
                                    .font(.system(size: 16, weight: selectedCategory == category ? .bold : .medium))
                                    .foregroundColor(selectedCategory == category ? .themeTextMain : .themeTextSecondary)
                                
                                Rectangle()
                                    .fill(selectedCategory == category ? Color.themePrimary : Color.clear)
                                    .frame(width: 20, height: 3)
                                    .cornerRadius(1.5)
                            }
                            .onTapGesture {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 10)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            NavigationLink(destination: TemplateDetailView(template: template)) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Image.bundle(template.coverImage)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(template.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.themeTextMain)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer(minLength: 0)
                                        
                                        HStack {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.themePrimary)
                                                .font(.system(size: 10))
                                            Text("\(String(format: "%.1f", Double(template.usageCount)/10000.0))w 人生成")
                                                .font(.system(size: 10))
                                                .foregroundColor(.themeTextSecondary)
                                        }
                                    }
                                    .padding(12)
                                }
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
            .navigationTitle("所有模板")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
