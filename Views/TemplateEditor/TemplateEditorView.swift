import SwiftUI

struct TemplateEditorView: View {
    @StateObject private var draft = TemplateDraft()
    @State private var currentStep: Int = 1
    @Environment(\.presentationMode) var presentationMode

    private let totalSteps: Int = 5
    private let stepTitles = ["基础信息", "封面图片", "填写规则", "图片样式", "预览发布"]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            stepIndicator
                .padding(.top, 12)
                .padding(.bottom, 6)

            TabView(selection: $currentStep) {
                EditorBasicInfoView(draft: draft).tag(1)
                EditorCoverView(draft: draft).tag(2)
                EditorFormRulesView(draft: draft).tag(3)
                EditorImageStyleView(draft: draft).tag(4)
                EditorPreviewPublishView(draft: draft).tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            bottomBar
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }

    // MARK: - Top bar
    private var headerBar: some View {
        ZStack {
            HStack {
                Button(action: {
                    if currentStep > 1 { currentStep -= 1 }
                    else { presentationMode.wrappedValue.dismiss() }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .padding(10)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("取消")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 2) {
                Text("发布玩法")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.themeTextMain)
                Text("\(currentStep) / \(totalSteps)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.themePrimary.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }

    // MARK: - Step indicator (numbered chips with dashes)
    private var stepIndicator: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                let stepNum = idx + 1
                let isActive = stepNum == currentStep
                let isDone = stepNum < currentStep
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isActive ? Color.themePrimary :
                                  (isDone ? Color.themePrimary.opacity(0.5) : Color.gray.opacity(0.15)))
                            .frame(width: 28, height: 28)
                        Text("\(stepNum)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isActive || isDone ? .themeTextMain : .themeTextSecondary)
                    }
                    Text(stepTitles[idx])
                        .font(.system(size: 11, weight: isActive ? .bold : .regular))
                        .foregroundColor(isActive ? .themeTextMain : .themeTextSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    // 允许点击跳转到任何已完成或当前的步骤
                    if stepNum <= currentStep + 1 { currentStep = stepNum }
                }

                if idx < totalSteps - 1 {
                    // 节点之间的虚线
                    Rectangle()
                        .frame(width: nil, height: 1)
                        .frame(height: 1)
                        .foregroundColor(stepNum < currentStep ? .themePrimary.opacity(0.5) : .gray.opacity(0.25))
                        .padding(.top, 13)
                        .frame(maxWidth: 20)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Bottom action
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                Button(action: { currentStep -= 1 }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("上一步")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .frame(maxWidth: 120)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(25)
                }
            }

            if currentStep < totalSteps {
                Button(action: { currentStep += 1 }) {
                    HStack {
                        Text("下一步")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.themeTextMain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themePrimary)
                    .cornerRadius(25)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: -2))
    }
}
