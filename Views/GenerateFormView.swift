import SwiftUI

struct GenerateFormView: View {
    let template: Template

    // ===== Legacy state (for built-in templates) =====
    @State private var nickname: String = ""
    @State private var defendant: String = ""
    @State private var topic: String = ""

    @State private var multiSelectData: Set<String> = []
    @State private var singleSelect1: String = ""
    @State private var singleSelect2: String = ""
    @State private var tone: String = ""
    @State private var customQuote: String = ""

    @State private var participants: [String] = ["", "", ""]

    // ===== Dynamic state for custom templates =====
    @State private var dynamicTextValues: [String: String] = [:]
    @State private var dynamicSingleValues: [String: String] = [:]
    @State private var dynamicMultiValues: [String: Set<String>] = [:]
    @State private var dynamicParticipants: [String: [String]] = [:]

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToResult = false

    private var isCustom: Bool { (template.customFields?.isEmpty == false) }

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isCustom {
                        renderDynamicForm()
                    } else {
                        renderForm()
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            }

            VStack {
                Button(action: generateAction) {
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
                .padding(.bottom, 30)
            }
            .background(Color.themeBackground)
            .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        }
        .background(Color.themeBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("填写信息")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setDefaultValues() }
        .toast(isPresented: $showAlert, message: alertMessage)
        .navigationDestination(isPresented: $navigateToResult) {
            ResultView(template: template, inputs: buildInputs())
        }
    }

    private func generateAction() {
        if isCustom {
            for f in template.customFields ?? [] {
                guard !f.label.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
                switch f.type {
                case .text, .number:
                    if (dynamicTextValues[f.id] ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
                        alertMessage = "请填写「\(f.label)」"
                        showAlert = true
                        return
                    }
                case .singleSelect:
                    if (dynamicSingleValues[f.id] ?? "").isEmpty {
                        alertMessage = "请选择「\(f.label)」"
                        showAlert = true
                        return
                    }
                case .multiSelect:
                    if (dynamicMultiValues[f.id] ?? []).isEmpty {
                        alertMessage = "请至少为「\(f.label)」选一项"
                        showAlert = true
                        return
                    }
                case .participants:
                    let names = (dynamicParticipants[f.id] ?? []).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    let minC = f.minCount ?? 3
                    if names.count < minC {
                        alertMessage = "「\(f.label)」至少需要 \(minC) 人"
                        showAlert = true
                        return
                    }
                }
            }
        } else if template.id == "friend_vote" {
            let validParticipants = participants.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if validParticipants.count < 3 {
                alertMessage = "至少输入 3 个朋友才能开局"
                showAlert = true
                return
            }
        }
        navigateToResult = true
    }

    private func buildInputs() -> [String: String] {
        if isCustom {
            var result: [String: String] = [:]
            for f in template.customFields ?? [] {
                let key = f.label
                switch f.type {
                case .text, .number:
                    result[key] = dynamicTextValues[f.id] ?? ""
                case .singleSelect:
                    result[key] = dynamicSingleValues[f.id] ?? ""
                case .multiSelect:
                    let picked = dynamicMultiValues[f.id] ?? []
                    result[key] = picked.joined(separator: "、")
                case .participants:
                    let names = (dynamicParticipants[f.id] ?? []).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    result[key] = names.joined(separator: "、")
                }
            }
            return result
        }

        var inputs: [String: String] = [:]
        inputs["nickname"] = nickname
        inputs["defendant"] = defendant
        inputs["topic"] = topic
        inputs["multiSelect"] = multiSelectData.joined(separator: ",")
        inputs["singleSelect1"] = singleSelect1
        inputs["singleSelect2"] = singleSelect2
        inputs["tone"] = tone
        inputs["customQuote"] = customQuote
        inputs["participants"] = participants.filter({ !$0.isEmpty }).joined(separator: ",")
        return inputs
    }

    private func setDefaultValues() {
        if isCustom { return }
        switch template.id {
        case "rich_card":
            singleSelect1 = "低调型"
            tone = "群聊整活"
        case "single_card":
            singleSelect1 = "单身"
            singleSelect2 = "被动型"
            tone = "毒舌吐槽"
        case "stay_up":
            singleSelect1 = "还能撑"
            tone = "搞笑"
        case "boss_card":
            singleSelect1 = "公司"
            tone = "群聊吐槽"
        case "group_judge":
            singleSelect1 = "群聊"
            singleSelect2 = "请奶茶"
            tone = "离谱判决"
        case "friend_vote":
            tone = "群聊整活榜"
        case "truth_dare":
            singleSelect1 = "随机"
            singleSelect2 = "中等"
            tone = "朋友"
        default:
            tone = "默认"
        }
    }

    // MARK: - Dynamic form (for custom templates)

    @ViewBuilder
    private func renderDynamicForm() -> some View {
        ForEach(template.customFields ?? []) { field in
            switch field.type {
            case .text:
                inputGroup(title: field.label) {
                    TextField(
                        field.placeholder.isEmpty ? "请输入\(field.label)" : field.placeholder,
                        text: dynamicTextBinding(for: field.id)
                    )
                }
            case .number:
                inputGroup(title: field.label) {
                    TextField(
                        field.placeholder.isEmpty ? "请输入数字" : field.placeholder,
                        text: dynamicTextBinding(for: field.id)
                    )
                    .keyboardType(.numberPad)
                }
            case .singleSelect:
                singleSelectGroup(
                    title: field.label,
                    options: field.options,
                    selection: dynamicSingleBinding(for: field.id)
                )
            case .multiSelect:
                multiSelectDynamicGroup(
                    title: field.label,
                    options: field.options,
                    fieldId: field.id
                )
            case .participants:
                dynamicParticipantsGroup(field: field)
            }
        }
    }

    @ViewBuilder
    private func dynamicParticipantsGroup(field: TemplateField) -> some View {
        let minC = field.minCount ?? 3
        let maxC = field.maxCount ?? 8
        let currentList: [String] = dynamicParticipants[field.id] ?? Array(repeating: "", count: minC)

        VStack(alignment: .leading, spacing: 12) {
            Text("\(field.label)（最少 \(minC) 人，最多 \(maxC) 人）")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            ForEach(currentList.indices, id: \.self) { index in
                HStack {
                    TextField("第 \(index + 1) 个名字", text: Binding(
                        get: { (dynamicParticipants[field.id]?[safe: index]) ?? "" },
                        set: { newVal in
                            var list = dynamicParticipants[field.id] ?? Array(repeating: "", count: minC)
                            while list.count <= index { list.append("") }
                            list[index] = newVal
                            dynamicParticipants[field.id] = list
                        }
                    ))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)

                    if currentList.count > minC {
                        Button(action: {
                            var list = dynamicParticipants[field.id] ?? []
                            if index < list.count {
                                list.remove(at: index)
                                dynamicParticipants[field.id] = list
                            }
                        }) {
                            Image(systemName: "minus.circle.fill").foregroundColor(.red)
                        }
                    }
                }
            }

            if currentList.count < maxC {
                Button(action: {
                    var list = dynamicParticipants[field.id] ?? Array(repeating: "", count: minC)
                    list.append("")
                    dynamicParticipants[field.id] = list
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加参与人")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.themePrimary)
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            if dynamicParticipants[field.id] == nil {
                dynamicParticipants[field.id] = Array(repeating: "", count: minC)
            }
        }
    }

    private func dynamicTextBinding(for id: String) -> Binding<String> {
        Binding(
            get: { dynamicTextValues[id] ?? "" },
            set: { dynamicTextValues[id] = $0 }
        )
    }

    private func dynamicSingleBinding(for id: String) -> Binding<String> {
        Binding(
            get: { dynamicSingleValues[id] ?? "" },
            set: { dynamicSingleValues[id] = $0 }
        )
    }

    @ViewBuilder
    private func multiSelectDynamicGroup(title: String, options: [String], fieldId: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let selected = (dynamicMultiValues[fieldId] ?? []).contains(option)
                    Text(option)
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selected ? Color.themePrimary : Color.white)
                        .foregroundColor(selected ? .black : .themeTextSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected ? Color.themePrimary : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .onTapGesture {
                            var current = dynamicMultiValues[fieldId] ?? []
                            if current.contains(option) { current.remove(option) } else { current.insert(option) }
                            dynamicMultiValues[fieldId] = current
                        }
                }
            }
        }
    }

    // MARK: - Legacy hardcoded form (built-in templates)

    @ViewBuilder
    private func renderForm() -> some View {
        switch template.id {
        case "rich_card":
            inputGroup(title: "TA的昵称") { TextField("请输入昵称", text: $nickname) }
            multiSelectGroup(title: "平时表现 (多选)", options: ["装穷", "点外卖不看价格", "说没钱但装备很新", "花钱很淡定", "经常突然请客"])
            singleSelectGroup(title: "伪装风格", options: ["低调型", "嘴硬型", "暴露型", "神秘型"], selection: $singleSelect1)
            singleSelectGroup(title: "生成语气", options: ["正经鉴定", "群聊整活", "毒舌吐槽", "可爱夸夸"], selection: $tone)

        case "single_card":
            inputGroup(title: "TA的昵称") { TextField("请输入昵称", text: $nickname) }
            singleSelectGroup(title: "当前状态", options: ["单身", "暧昧中", "刚失恋", "佛系随缘", "嘴硬不想谈"], selection: $singleSelect1)
            singleSelectGroup(title: "社交风格", options: ["主动型", "被动型", "社恐型", "海王嫌疑", "纯爱战士"], selection: $singleSelect2)
            singleSelectGroup(title: "生成语气", options: ["甜甜鼓励", "毒舌吐槽", "玄学运势", "朋友调侃"], selection: $tone)

        case "stay_up":
            inputGroup(title: "TA的昵称") { TextField("请输入昵称", text: $nickname) }
            multiSelectGroup(title: "熬夜原因 (多选)", options: ["刷视频", "打游戏", "赶作业", "加班", "想太多", "单纯不困"])
            singleSelectGroup(title: "当前状态", options: ["还能撑", "快不行了", "已经灵魂出窍", "明天一定早睡"], selection: $singleSelect1)
            singleSelectGroup(title: "生成语气", options: ["扎心", "搞笑", "温柔提醒"], selection: $tone)

        case "boss_card":
            inputGroup(title: "TA的昵称") { TextField("请输入昵称", text: $nickname) }
            multiSelectGroup(title: "老板气质 (多选)", options: ["爱画饼", "气场强", "说话像开会", "喜欢总结", "表情严肃"])
            singleSelectGroup(title: "场景", options: ["公司", "班级", "宿舍", "朋友局"], selection: $singleSelect1)
            singleSelectGroup(title: "生成语气", options: ["认真鉴定", "群聊吐槽", "夸张整活"], selection: $tone)

        case "group_judge":
            inputGroup(title: "被告名字") { TextField("请输入被告名字", text: $defendant) }
            multiSelectGroup(title: "罪名 (多选)", options: ["已读不回", "迟到", "放鸽子", "装没看见", "只发表情", "关键时刻消失"])
            singleSelectGroup(title: "案发场景", options: ["群聊", "饭局", "班级", "宿舍", "办公室"], selection: $singleSelect1)
            singleSelectGroup(title: "惩罚方式", options: ["请奶茶", "发红包", "公开道歉", "下次请客", "当气氛组"], selection: $singleSelect2)
            singleSelectGroup(title: "判决语气", options: ["正经判决", "离谱判决", "毒舌判决"], selection: $tone)

        case "friend_vote":
            inputGroup(title: "投票主题") { TextField("例如：谁最可能先脱单", text: $topic) }
            participantsGroup()
            singleSelectGroup(title: "榜单风格", options: ["正经榜", "离谱榜", "群聊整活榜", "友情伤害榜"], selection: $tone)

        case "truth_dare":
            singleSelectGroup(title: "模式", options: ["真心话", "大冒险", "随机"], selection: $singleSelect1)
            singleSelectGroup(title: "难度", options: ["轻松", "中等", "社死"], selection: $singleSelect2)
            singleSelectGroup(title: "关系", options: ["朋友", "同学", "情侣", "同事"], selection: $tone)
            inputGroup(title: "昵称 (可选)") { TextField("如果不填则直接出题", text: $nickname) }

        default:
            inputGroup(title: "TA的昵称") { TextField("请输入昵称", text: $nickname) }
            singleSelectGroup(title: "生成语气", options: ["可爱夸夸", "毒舌吐槽", "正经鉴定"], selection: $tone)
        }

        // Custom Quote Section (VIP-only, only on built-in templates)
        if VipManager.shared.isVip {
            inputGroup(title: "自定义文案 (VIP专属)") {
                TextField("选填，将替换默认生成的文案", text: $customQuote)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image.bundle("vip_icon")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("自定义文案 (VIP专属)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.themeTextMain)
                }
                HStack {
                    Text("开通 VIP 即可随意定制专属文案内容")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)
                    Spacer()
                    NavigationLink(destination: PayWallView()) {
                        Text("去开通")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.themeTextMain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.themePrimary)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }

    @ViewBuilder
    private func inputGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            content()
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private func multiSelectGroup(title: String, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .font(.system(size: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(multiSelectData.contains(option) ? Color.themePrimary : Color.white)
                        .foregroundColor(multiSelectData.contains(option) ? .black : .themeTextSecondary)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(multiSelectData.contains(option) ? Color.themePrimary : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .onTapGesture {
                            if multiSelectData.contains(option) {
                                multiSelectData.remove(option)
                            } else {
                                multiSelectData.insert(option)
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func singleSelectGroup(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .font(.system(size: 14))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection.wrappedValue == option ? Color.themePrimary : Color.white)
                            .foregroundColor(selection.wrappedValue == option ? .black : .themeTextSecondary)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selection.wrappedValue == option ? Color.themePrimary : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .onTapGesture {
                                selection.wrappedValue = option
                            }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func participantsGroup() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参与人 (至少3个，最多8个)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextMain)

            ForEach(0..<participants.count, id: \.self) { index in
                HStack {
                    TextField("名字", text: $participants[index])
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)

                    if participants.count > 3 {
                        Button(action: {
                            participants.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            if participants.count < 8 {
                Button(action: {
                    participants.append("")
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("添加参与人")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.themePrimary)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// Safe subscript for arrays - returns nil instead of crashing on out-of-range index.
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Helper for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > width {
                height += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var pt = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if pt.x + size.width > bounds.maxX {
                pt.x = bounds.minX
                pt.y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: pt, proposal: .unspecified)
            pt.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
