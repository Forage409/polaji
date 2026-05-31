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
                                allowedThemeIds: allowedThemeIds
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
            Task {
                try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_generate")
            }
        }
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
                createdAt: ISO8601DateFormatter().string(from: Date())
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
            exportMode: true
        )
        return ImageExportManager.shared.renderImage(from: view, width: 350)
    }

    private func saveImageAndWork() {
        guard let image = getRenderedImage() else { return }
        let card = makeCardForPublishing()

        ImageExportManager.shared.saveImageToPhotos(image) { success in
            if success, let path = ImageExportManager.shared.saveImageToDocuments(image, fileName: "\(card.id).jpg") {
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
                alertMessage = "保存成功，已存入相册和我的作品！"
            } else {
                alertMessage = success ? "保存图片文件失败" : "保存相册失败，请在设置中允许 App 访问相册。"
            }
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
