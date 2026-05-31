import SwiftUI

struct UnifiedResultCardUI: View {
    let document: ResultCardDocument
    var showWatermark: Bool = false
    var exportMode: Bool = false

    private var pack: ResultThemePack { document.themePack }

    var body: some View {
        ZStack {
            backgroundLayer
            decorationLayer

            VStack(alignment: .leading, spacing: 14) {
                layoutBadge
                ForEach(document.moduleOrder) { module in
                    if shouldShow(module) {
                        moduleView(module)
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 350)
        .overlay(
            RoundedRectangle(cornerRadius: exportMode ? 0 : 24)
                .stroke(borderColor, lineWidth: document.layout == .verdict ? 3 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: exportMode ? 0 : 24))
        .shadow(color: exportMode ? .clear : .black.opacity(0.14), radius: 18, x: 0, y: 8)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            pack.cardColor
            Image.bundle(document.backgroundId)
                .resizable()
                .scaledToFill()
                .opacity(0.72)
            LinearGradient(
                colors: [pack.cardColor.opacity(0.2), pack.cardColor.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipped()
    }

    @ViewBuilder
    private var decorationLayer: some View {
        ZStack {
            ForEach(Array(document.decorationStickerIds.prefix(3).enumerated()), id: \.offset) { index, imageName in
                Image.bundle(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: index == 0 ? 58 : 44, height: index == 0 ? 58 : 44)
                    .rotationEffect(.degrees(index == 1 ? -12 : (index == 2 ? 10 : 0)))
                    .position(decorationPosition(index))
                    .opacity(0.9)
            }
        }
        .allowsHitTesting(false)
    }

    private func decorationPosition(_ index: Int) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: 308, y: 44)
        case 1: return CGPoint(x: 34, y: 250)
        default: return CGPoint(x: 306, y: 470)
        }
    }

    private func shouldShow(_ module: ResultModuleKind) -> Bool {
        if module.isRequired { return true }
        if document.hiddenModules.contains(module) { return false }
        switch module {
        case .hero: return document.heroStickerId != nil
        case .stats: return !document.stats.isEmpty
        case .fields: return !document.fields.isEmpty
        case .evidence: return !document.evidence.isEmpty
        case .result: return !document.resultLevel.isEmpty || !document.finalComment.isEmpty
        case .quote: return !document.quote.isEmpty
        default: return true
        }
    }

    @ViewBuilder
    private func moduleView(_ module: ResultModuleKind) -> some View {
        switch module {
        case .header:
            header
        case .hero:
            hero
        case .stats:
            stats
        case .fields:
            fields
        case .evidence:
            evidence
        case .result:
            result
        case .quote:
            quote
        case .footer:
            footer
        }
    }

    private var header: some View {
        VStack(alignment: document.layout == .socialPoster ? .center : .leading, spacing: 5) {
            Text(document.title)
                .font(.system(size: document.layout == .socialPoster ? 30 : 26, weight: .heavy))
                .foregroundColor(pack.textColor)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
            if !document.subtitle.isEmpty {
                Text(document.subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(pack.textColor.opacity(0.72))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: document.layout == .socialPoster ? .center : .leading)
        .multilineTextAlignment(document.layout == .socialPoster ? .center : .leading)
        .padding(.trailing, 38)
    }

    @ViewBuilder
    private var hero: some View {
        if let imageName = document.heroStickerId {
            HStack {
                Spacer()
                Image.bundle(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: document.layout == .socialPoster ? 156 : 112)
                Spacer()
            }
        }
    }

    private var stats: some View {
        VStack(spacing: 8) {
            ForEach(document.stats) { stat in
                VStack(spacing: 4) {
                    HStack {
                        Text(stat.name)
                        Spacer()
                        Text("\(stat.value)%")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(pack.textColor)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(pack.textColor.opacity(0.12))
                            Capsule()
                                .fill(pack.accentColor)
                                .frame(width: proxy.size.width * CGFloat(min(max(stat.value, 0), 100)) / 100)
                        }
                    }
                    .frame(height: 7)
                }
            }
        }
        .padding(12)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(document.fields) { field in
                VStack(alignment: .leading, spacing: 3) {
                    Text(field.label)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(pack.textColor.opacity(0.62))
                    Text(field.value.isEmpty ? "-" : field.value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(pack.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var evidence: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(document.evidence.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: evidenceIcon)
                        .foregroundColor(pack.accentColor)
                        .font(.system(size: 13))
                    Text(evidencePrefix(index) + item)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(pack.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var result: some View {
        VStack(spacing: 6) {
            if !document.resultLevel.isEmpty {
                Text(document.resultLevel)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(pack.accentColor)
            }
            if !document.finalComment.isEmpty {
                Text(document.finalComment)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(pack.textColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(panelBackground.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var quote: some View {
        Text("“\(document.quote)”")
            .font(.system(size: 14, weight: .bold))
            .italic()
            .foregroundColor(pack.textColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image.bundle("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(showWatermark ? "整活局生成 · zhenghuoju.com" : "内容仅供娱乐")
            Spacer()
            Text(document.createdAt)
                .lineLimit(1)
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundColor(pack.textColor.opacity(0.55))
        .padding(.top, 2)
    }

    private var panelBackground: Color {
        document.layout == .verdict ? Color.white.opacity(0.82) : Color.white.opacity(0.68)
    }

    private var borderColor: Color {
        document.layout == .verdict ? pack.accentColor.opacity(0.72) : pack.accentColor.opacity(0.2)
    }

    private var evidenceIcon: String {
        switch document.layout {
        case .ranking: return "medal.fill"
        case .verdict: return "seal.fill"
        case .challenge: return "checklist"
        default: return "checkmark.circle.fill"
        }
    }

    private func evidencePrefix(_ index: Int) -> String {
        switch document.layout {
        case .ranking: return "TOP \(index + 1)  "
        case .challenge: return "任务 \(index + 1)  "
        default: return ""
        }
    }

    private var layoutBadge: some View {
        HStack {
            Text(layoutBadgeText)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(pack.textColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(pack.accentColor.opacity(0.18))
                .clipShape(Capsule())
            Spacer()
            if document.layout == .verdict {
                Image(systemName: "seal.fill")
                    .foregroundColor(pack.accentColor)
            }
        }
    }

    private var layoutBadgeText: String {
        switch document.layout {
        case .report: return "PERSONAL REPORT"
        case .ranking: return "FRIEND RANKING"
        case .verdict: return "GROUP VERDICT"
        case .challenge: return "TODAY CHALLENGE"
        case .socialPoster: return "SOCIAL POSTER"
        }
    }
}
