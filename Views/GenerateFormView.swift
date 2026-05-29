import SwiftUI

struct GenerateFormView: View {
    let template: Template
    
    @State private var inputValues: [String: String] = [:]
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(template.fields, id: \.self) { field in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(fieldTitle(for: field))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeTextMain)
                            
                            TextField("请输入\(fieldTitle(for: field))", text: Binding(
                                get: { inputValues[field] ?? "" },
                                set: { inputValues[field] = $0 }
                            ))
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
            }
            
            VStack {
                NavigationLink(destination: ResultView(template: template, inputs: inputValues)) {
                    Text("生成结果")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.themePrimary)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30) // Fixed safeAreaInsets deprecation
            }
            .background(Color.themeBackground)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("填写信息")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func fieldTitle(for field: String) -> String {
        switch field {
        case "nickname": return "昵称"
        case "mood": return "心情/状态"
        case "defendant": return "被告名字"
        case "punishment": return "惩罚方式"
        case "topic": return "投票主题"
        default: return field
        }
    }
}
