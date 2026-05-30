import SwiftUI

struct TemplateEditorView: View {
    @StateObject private var draft = TemplateDraft()
    @State private var currentStep: Int = 1
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            progressBar
            
            TabView(selection: $currentStep) {
                EditorBasicInfoView(draft: draft)
                    .tag(1)
                EditorCoverView(draft: draft)
                    .tag(2)
                EditorFormRulesView(draft: draft)
                    .tag(3)
                EditorResultRulesView(draft: draft)
                    .tag(4)
                EditorPreviewPublishView(draft: draft)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            bottomBar
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
    
    private var headerBar: some View {
        HStack {
            Button(action: {
                if currentStep > 1 {
                    currentStep -= 1
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.themeTextMain)
            }
            Spacer()
            Text(stepTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.themeTextMain)
            Spacer()
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("取消")
                    .font(.system(size: 16))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                Rectangle()
                    .fill(Color.themePrimary)
                    .frame(width: geo.size.width * CGFloat(currentStep) / 5.0, height: 4)
                    .animation(.linear, value: currentStep)
            }
        }
        .frame(height: 4)
    }
    
    private var bottomBar: some View {
        HStack {
            if currentStep > 1 {
                Button(action: { currentStep -= 1 }) {
                    Text("上一步")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(25)
                }
            }
            
            if currentStep < 5 {
                Button(action: { currentStep += 1 }) {
                    Text("下一步")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themePrimary)
                        .cornerRadius(25)
                }
            } else {
                Button(action: {
                    // Publish Action handled in step 5
                }) {
                    Text("发布玩法")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themePrimary)
                        .cornerRadius(25)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 1: return "基础信息"
        case 2: return "封面图片"
        case 3: return "填写规则"
        case 4: return "结果规则"
        case 5: return "预览与发布"
        default: return "编辑玩法"
        }
    }
}
