import SwiftUI

struct AITemplateCopySheet: View {
    @ObservedObject var draft: TemplateDraft
    @Environment(\.dismiss) private var dismiss

    @State private var tone: AITone = .moments
    @State private var receipt: AITemplateCopyReceipt?
    @State private var rejectionReason: String?
    @State private var isLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("AI 会为玩法生成指标、趣味证据、结论和结果等级。采用后仍可继续手动调整。")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)

                    if let rejectionReason {
                        rejectionCard(reason: rejectionReason)
                    } else {
                        Picker("语气", selection: $tone) {
                            ForEach(AITone.allCases) { item in
                                Text(item.displayName).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                    }

                    Button(action: generate) {
                        HStack {
                            if isLoading { ProgressView().scaleEffect(0.8) }
                            Text(isLoading ? "AI 正在审核并构思..." : (receipt == nil ? "生成玩法文案库" : "重新生成一套"))
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.themePrimary)
                        .cornerRadius(24)
                    }
                    .disabled(isLoading)

                    if let receipt {
                        preview(title: "指标", values: receipt.stats)
                        preview(title: "趣味证据池", values: receipt.evidencePool)
                        preview(title: "结论池", values: receipt.finalPool)
                        preview(title: "结果等级", values: receipt.levels)

                        Button {
                            let library = receipt.library.normalized()
                            guard library.isUsable else {
                                alertMessage = "AI 文案不完整，请重新生成"
                                showAlert = true
                                return
                            }
                            draft.resultConfig.copyLibrary = library
                            dismiss()
                        } label: {
                            Text("采用这套文案")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "7B61FF"))
                                .cornerRadius(25)
                        }
                    }
                }
                .padding(18)
            }
            .background(Color.themeBackground)
            .navigationTitle("AI 帮写玩法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .toast(isPresented: $showAlert, message: alertMessage)
        }
    }

    private func rejectionCard(reason: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "shield.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 3) {
                    Text("暂时无法生成")
                        .font(.system(size: 16, weight: .heavy))
                    Text("玩法内容未通过安全检查")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
            }
            Text(reason)
                .font(.system(size: 13))
                .foregroundColor(.themeTextMain)
                .fixedSize(horizontal: false, vertical: true)
            Text("请返回修改玩法名称、描述或填写项后再试。")
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private func preview(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
            ForEach(values, id: \.self) { value in
                Text("· \(value)")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
    }

    private func generate() {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            alertMessage = "请先填写玩法标题"
            showAlert = true
            return
        }
        rejectionReason = nil
        receipt = nil
        isLoading = true
        Task {
            do {
                let generated = try await AIService.shared.generateTemplateCopy(
                    title: title,
                    description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: draft.category,
                    fields: draft.fields,
                    tone: tone
                )
                await MainActor.run {
                    receipt = generated
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let serviceError = error as? AIServiceError,
                       case let .ugcRejected(reason) = serviceError {
                        rejectionReason = reason
                    } else {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        }
    }
}
