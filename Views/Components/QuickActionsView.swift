import SwiftUI

struct QuickActionsScrollView: View {
    let actions = [
        ("群聊判官", "icon_judge", "group_judge"),
        ("好友投票", "icon_vote", "friend_vote"),
        ("今日人设", "icon_persona", "persona_card"),
        ("真心话大冒险", "icon_truth_dare", "truth_dare")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<actions.count, id: \.self) { index in
                NavigationLink(destination: TemplateDetailView(template: getTemplate(for: actions[index].2))) {
                    VStack(spacing: 8) {
                        Image.bundle(actions[index].1)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        Text(actions[index].0)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.themeTextMain)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }
    
    func getTemplate(for id: String) -> Template {
        return MockData.allTemplates.first(where: { $0.id == id }) ?? MockData.allTemplates[0]
    }
}
