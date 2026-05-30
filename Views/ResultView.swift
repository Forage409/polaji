import SwiftUI

struct ResultView: View {
    let template: Template
    let initialInputs: [String: String]
    
    @State private var currentInputs: [String: String] = [:]
    @State private var generatedCard: GeneratedCard?
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPublishSheet = false
    
    init(template: Template, inputs: [String: String]) {
        self.template = template
        self.initialInputs = inputs
        _currentInputs = State(initialValue: inputs)
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if let card = generatedCard {
                        ResultCardUI(card: card)
                            .padding(.vertical, 30)
                    } else {
                        ProgressView("正在生成...")
                            .padding(.vertical, 50)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            VStack(spacing: 12) {
                // Reroll and Change Tone removed per P0.6 requirements
                
                HStack(spacing: 12) {
                    Button(action: {
                        saveImageAndWork()
                    }) {
                        Text("保存图片")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeTextMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.themePrimary)
                            .cornerRadius(25)
                    }
                    
                    Button(action: {
                        shareImage()
                    }) {
                        Text("分享给好友")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.themeTextMain)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.themePrimary)
                            .cornerRadius(25)
                    }
                }
                
                Button(action: {
                    showingPublishSheet = true
                }) {
                    Text("发布到广场")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.themePrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.themePrimary.opacity(0.1))
                        .cornerRadius(25)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("返回修改")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("生成结果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if generatedCard == nil {
                generateCard()
            }
        }
        .toast(isPresented: $showingAlert, message: alertMessage)
        .sheet(isPresented: $showingPublishSheet) {
            if let card = generatedCard, let img = getRenderedImage() {
                PublishWorkView(template: template, card: card, image: img)
            }
        }
    }
    
    private func generateCard() {
        generatedCard = CardGenerator.shared.generate(templateId: template.id, inputs: currentInputs)
        if generatedCard != nil {
            Task {
                try? await RemoteTemplateService.shared.sendTemplateEvent(templateId: template.id, eventType: "template_generate")
            }
        }
    }
    
    private func changeTone() {
        let tones = ["正经鉴定", "群聊整活", "毒舌吐槽", "可爱夸夸", "扎心", "搞笑", "离谱判决"]
        var newTone = tones.randomElement()!
        while newTone == currentInputs["tone"] {
            newTone = tones.randomElement()!
        }
        currentInputs["tone"] = newTone
        generateCard()
    }
    
    private func getRenderedImage() -> UIImage? {
        guard let card = generatedCard else { return nil }
        let isVip = VipManager.shared.isVip
        let uiView = ResultCardUI(card: card, exportMode: true, showWatermark: !isVip)
        return ImageExportManager.shared.renderImage(from: uiView, width: 350)
    }
    
    private func saveImageAndWork() {
        guard let image = getRenderedImage(), let card = generatedCard else { return }
        
        ImageExportManager.shared.saveImageToPhotos(image) { success in
            if success {
                if let savedPath = ImageExportManager.shared.saveImageToDocuments(image, fileName: "\(card.id).jpg") {
                    let work = Work(id: card.id, templateId: template.id, title: card.title, imagePath: savedPath, createdAt: card.createdAt, category: template.category, isShared: false)
                    WorksStore.shared.saveWork(work)
                    alertMessage = "保存成功，已存入相册和我的作品！"
                } else {
                    alertMessage = "保存图片文件失败"
                }
            } else {
                alertMessage = "保存相册失败，请在设置中允许 App 访问相册。"
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
