import SwiftUI

struct ResultThemePack: Identifiable, Equatable {
    let id: String
    let displayName: String
    let tagline: String
    let backgrounds: [String]
    let heroStickers: [String]
    let decorationStickers: [String]
    let accentHex: String
    let textHex: String
    let cardHex: String

    var accentColor: Color { Color(hex: accentHex) }
    var textColor: Color { Color(hex: textHex) }
    var cardColor: Color { Color(hex: cardHex) }

    static let all: [ResultThemePack] = [
        pack("pop_party", "派对气氛组", "明黄紫色，朋友局首选", "7B61FF", "241A38", "FFF7D6"),
        pack("pink_crush", "心动粉红", "爱心贴纸，甜甜但不腻", "F15B88", "451D31", "FFF0F5"),
        pack("midnight_mode", "深夜在线", "霓虹深蓝，熬夜状态", "7A8CFF", "EEF1FF", "20284A"),
        pack("office_satire", "职场摸鱼", "便签文件，轻松吐槽", "E59332", "3A2A1A", "FFF5DF"),
        pack("courtroom_red", "临时开庭", "红黑印章，群聊判官", "D74B4B", "3C1717", "FFF0EA"),
        pack("fortune_gold", "好运富贵", "金色绿色，财运拉满", "D29B30", "3A2C12", "FFF6DA"),
        pack("campus_fun", "校园玩伴", "青绿手帐，青春朋友局", "34A58B", "163E38", "EFFFF8"),
        pack("meme_news", "趣味头条", "复古报纸，今日大事件", "E24B3B", "2B2724", "FFF8EB"),
        pack("dreamy_persona", "今日人设", "紫粉星星，轻盈梦幻", "8B67E8", "302147", "F8F0FF"),
        pack("weekend_chill", "周末松弛", "橙蓝休闲，慢慢生活", "F07F4F", "2C3444", "FFF2E8")
    ]

    static func find(_ id: String) -> ResultThemePack {
        all.first(where: { $0.id == id }) ?? all[8]
    }

    private static func pack(
        _ id: String,
        _ displayName: String,
        _ tagline: String,
        _ accent: String,
        _ text: String,
        _ card: String
    ) -> ResultThemePack {
        ResultThemePack(
            id: id,
            displayName: displayName,
            tagline: tagline,
            backgrounds: ["theme_\(id)_bg_1", "theme_\(id)_bg_2"],
            heroStickers: ["theme_\(id)_hero_1", "theme_\(id)_hero_2"],
            decorationStickers: (1...4).map { "theme_\(id)_deco_\($0)" },
            accentHex: accent,
            textHex: text,
            cardHex: card
        )
    }
}
