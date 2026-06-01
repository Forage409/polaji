import SwiftUI

struct ResultView: View {
    let template: Template
    let initialInputs: [String: String]

    @State private var currentInputs: [String: String]
    @State private var resultDocument: ResultCardDocument?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPublishSheet = false
    @State private var showingEditorSheet = false
    @State private var showingVIPPaywall = false
    @State private var showingUpgradeCard = false
    @State private var paywallContext: VIPPaywallContext = .general
    @State private var allowFreeTrialFromPaywall = false
    @State private var aiQuota: AIQuotaStatus?
    @State private var isAIOptimizing = false
    @ObservedObject private var vip = VipManager.shared
    @Environment(\.presentationMode) var presentationMode

    private var isCustom: Bool { template.customFields?.isEmpty == false }

    init(template: Template, inputs: [String: String]) {
        self.template = template
        self.initialInputs = inputs
        _currentInputs = State(initialValue: inputs)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let document = resultDocument {
                        UnifiedResultCardUI(document: document)
                            .padding(.top, 24)

                        Button(action: { showingEditorSheet = true }) {
                            Label("编辑结果图", systemImage: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.themeTextMain)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.bottom, 16)

                        aiActions
                    } else {
                        ProgressView("正在生成...")
                            .padding(.vertical, 60)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            actionBar
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("生成结果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if resultDocument == nil {
                generateDocument()
            }
            Task { aiQuota = try? await AIService.shared.fetchStatus() }
        }
        .toast(isPresented: $showingAlert, message: alertMessage)
        .sheet(isPresented: $showingEditorSheet) {
            NavigationStack {
                ScrollView {
                    if let document = resultDocument {
                        VStack(spacing: 8) {
                            UnifiedResultCardUI(document: document)
                                .padding(.top, 16)
                            ResultFineTunePanel(
                                document: Binding(
                                    get: { resultDocument! },
                                    set: { resultDocument = $0 }
                                ),
                                allowedThemeIds: allowedThemeIds,
                                onLockedThemeTap: {
                                    showingEditorSheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        presentPaywall(.theme)
                                    }
                                }
                            )
                        }
                    }
                }
                .background(Color.themeBackground)
                .navigationTitle("编辑结果图")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") { showingEditorSheet = false }
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPublishSheet) {
            if let image = getRenderedImage() {
                PublishWorkView(template: template, card: makeCardForPublishing(), image: image)
            }
        }
        .sheet(isPresented: $showingVIPPaywall) {
            NavigationStack {
                VIPPaywallView(
                    context: paywallContext,
                    freeTrialRemaining: aiQuota?.remaining ?? 3,
                    onTryFree: allowFreeTrialFromPaywall ? { runAI(.default) } : nil
                )
            }
        }
        .sheet(isPresented: $showingUpgradeCard) {
            VIPUpgradeCardView {
                showingUpgradeCard = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    presentPaywall(.general)
                }
            } onDismiss: {
                showingUpgradeCard = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionButton(title: "保存图片", fill: .themePrimary) {
                    saveImageAndWork()
                }
                actionButton(title: "分享给好友", fill: .themePrimary) {
                    shareImage()
                }
            }

            Button(action: { showingPublishSheet = true }) {
                Text("发布到广场")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.themePrimary.opacity(0.1))
                    .cornerRadius(25)
            }

            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("返回修改")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.themeBackground)
    }

    private var aiActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("这张图还能更好笑")
                        .font(.system(size: 17, weight: .heavy))
                    Text(aiQuotaText)
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.themePrimary)
            }

            HStack(spacing: 8) {
                aiButton("AI 优化文案", icon: "sparkles") {
                    tapAI(.default)
                }

                Menu {
                    ForEach(AITone.allCases.filter { $0 != .default }) { tone in
                        Button(tone.displayName) { tapAI(tone) }
                    }
                } label: {
                    Label("换个语气", systemImage: "quote.bubble")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeTextMain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color.themePrimary.opacity(0.18))
                        .cornerRadius(18)
                }
            }

            Button {
                if !vip.isVip { presentPaywall(.watermark) }
            } label: {
                Label(vip.isVip ? "导出图片已去水印" : "去水印", systemImage: vip.isVip ? "checkmark.seal.fill" : "drop")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(vip.isVip ? .themeSuccessGreen : .themeTextMain)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func aiButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isAIOptimizing {
                    ProgressView().scaleEffect(0.75)
                } else {
                    Image(systemName: icon)
                }
                Text(isAIOptimizing ? "AI 优化中..." : title)
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.themeTextMain)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(Color.themePrimary)
            .cornerRadius(18)
        }
        .disabled(isAIOptimizing)
    }

    private func actionButton(title: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.themeTextMain)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(fill)
                .cornerRadius(25)
        }
    }

    private var resultConfig: TemplateResultConfig {
        isCustom ? template.resultConfig.normalized() : TemplateResultConfig.official(for: template.id)
    }

    private var allowedThemeIds: [String] {
        resultConfig.allowedThemePackIds
    }

    private func generateDocument() {
        if isCustom {
            resultDocument = ResultCardDocument.fromCustomTemplate(template, inputs: currentInputs)
        } else {
            let card = CardGenerator.shared.generate(templateId: template.id, inputs: currentInputs)
            resultDocument = ResultCardDocument.fromGeneratedCard(card, config: resultConfig)
        }

        if resultDocument != nil {
            normalizeThemeAccess()
            if VipManager.shared.recordGenerationAndShouldSuggestUpgrade() {
                showingUpgradeCard = true
            }
            Task {
                try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_generate")
            }
        }
    }

    private func normalizeThemeAccess() {
        guard !vip.isVip, var document = resultDocument,
              !VipManager.basicThemePackIds.contains(document.themePackId) else { return }
        let replacement = allowedThemeIds.first(where: { VipManager.basicThemePackIds.contains($0) }) ?? "dreamy_persona"
        document.applyTheme(replacement)
        resultDocument = document
    }

    private var aiQuotaText: String {
        if let quota = aiQuota {
            return quota.isVip ? "VIP 滚动 24 小时剩余 \(quota.remaining) 次" : "今日免费剩余 \(quota.remaining) 次 AI 优化"
        }
        return vip.isVip ? "VIP 可使用 AI 爆梗与全部语气" : "免费用户每天可试用 3 次 AI 优化"
    }

    private func tapAI(_ tone: AITone) {
        guard !isAIOptimizing else { return }
        if tone != .default && !vip.isVip {
            presentPaywall(.tone)
            return
        }
        if tone == .default && VipManager.shared.shouldPresentAITrialPaywall() {
            presentPaywall(.aiTrial, allowTrial: true)
            return
        }
        runAI(tone)
    }

    private func runAI(_ tone: AITone) {
        guard let document = resultDocument else { return }
        isAIOptimizing = true
        Task {
            do {
                let receipt = try await AIService.shared.optimize(document: document, userInputs: currentInputs, tone: tone)
                await MainActor.run {
                    guard var updated = resultDocument else { return }
                    updated.title = receipt.title
                    updated.subtitle = receipt.subtitle
                    updated.evidence = receipt.evidence
                    updated.resultLevel = receipt.resultLevel
                    updated.quote = receipt.quote
                    updated.finalComment = receipt.finalComment
                    resultDocument = updated
                    aiQuota = receipt.quota
                    isAIOptimizing = false
                    alertMessage = "AI 优化完成"
                    showingAlert = true
                }
            } catch let error as AIServiceError {
                await MainActor.run {
                    isAIOptimizing = false
                    if case .quotaExceeded = error {
                        presentPaywall(.quota)
                    } else if case .vipRequired = error {
                        presentPaywall(.general)
                    } else {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isAIOptimizing = false
                    alertMessage = "AI 服务暂时不可用，请稍后重试。"
                    showingAlert = true
                }
            }
        }
    }

    private func presentPaywall(_ context: VIPPaywallContext, allowTrial: Bool = false) {
        paywallContext = context
        allowFreeTrialFromPaywall = allowTrial
        showingVIPPaywall = true
    }

    private func makeCardForPublishing() -> GeneratedCard {
        guard let document = resultDocument else {
            return GeneratedCard(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.name,
                subtitle: "",
                mainImageName: "",
                stats: [],
                quote: "",
                evidenceList: [],
                resultLevel: "",
                finalComment: "",
                styleTone: "",
                participants: [],
                templateType: "custom",
                createdAt: LocalTimeFormatter.now()
            )
        }

        return GeneratedCard(
            id: document.id,
            templateId: template.id,
            title: document.title,
            subtitle: document.subtitle,
            mainImageName: document.heroStickerId ?? "",
            stats: document.stats,
            quote: document.quote,
            evidenceList: document.evidence,
            resultLevel: document.resultLevel,
            finalComment: document.finalComment,
            styleTone: document.themePackId,
            participants: [],
            templateType: document.layout.rawValue,
            createdAt: document.createdAt
        )
    }

    private func getRenderedImage() -> UIImage? {
        guard let document = resultDocument else { return nil }
        let view = UnifiedResultCardUI(
            document: document,
            showWatermark: !VipManager.shared.isVip,
            exportMode: true,
            cardWidth: 350
        )
        return ImageExportManager.shared.renderImage(from: view, width: 350)
    }

    private func saveImageAndWork() {
        guard let image = getRenderedImage() else { return }
        let card = makeCardForPublishing()

        guard let path = ImageExportManager.shared.saveImageToDocuments(image, fileName: "\(card.id).jpg") else {
            alertMessage = "保存图片文件失败"
            showingAlert = true
            return
        }
        WorksStore.shared.saveWork(
            Work(
                id: card.id,
                templateId: template.id,
                title: card.title,
                imagePath: path,
                createdAt: card.createdAt,
                category: template.category,
                isShared: false
            )
        )

        ImageExportManager.shared.saveImageToPhotos(image) { success in
            alertMessage = success
                ? "保存成功，已存入相册和我的作品！"
                : "已存入我的作品。相册保存失败，请在设置中允许 App 访问相册。"
            showingAlert = true
        }
    }

    private func shareImage() {
        guard let image = getRenderedImage() else { return }
        ImageExportManager.shared.shareImage(image)
        Task {
            try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_share")
        }
    }
}
