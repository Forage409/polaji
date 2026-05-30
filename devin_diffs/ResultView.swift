
+5
−3
    
    @State private var currentInputs: [String: String] = [:]
    @State private var generatedCard: GeneratedCard?
    @StateObject private var store = WorksStore()
    @ObservedObject private var store = WorksStore.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
        generateCard()
    }
    
    @MainActor
    private func getRenderedImage() -> UIImage? {
        guard let card = generatedCard else { return nil }
        let uiView = ResultCardUI(card: card)
        return ImageExportManager.shared.renderImage(from: uiView, size: CGSize(width: 350, height: 520))
        let isVip = VipManager.shared.isVip
        let exportCard = ResultCardUI(card: card, exportMode: true, showWatermark: !isVip)
        return ImageExportManager.shared.renderImage(from: exportCard, size: CGSize(width: 350, height: 520))
    }
    
    private func saveImageAndWork() {

AboutView.swift
