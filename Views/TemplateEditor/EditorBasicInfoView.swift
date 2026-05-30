import SwiftUI

struct EditorBasicInfoView: View {
    @ObservedObject var draft: TemplateDraft
    let categories = ["人设卡", "判官", "投票", "趣味", "其他"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("玩法名称")
                        .font(.system(size: 14, weight: .bold))
                    TextField("输入最多 15 个字的名称", text: $draft.title)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("玩法描述")
                        .font(.system(size: 14, weight: .bold))
                    TextEditor(text: $draft.description)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("分类")
                        .font(.system(size: 14, weight: .bold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat)
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(draft.category == cat ? Color.themePrimary : Color.white)
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        draft.category = cat
                                    }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
