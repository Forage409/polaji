import Foundation
import Combine
 
final class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    
    private let nicknameKey = "ZhengHuoJu_Profile_Nickname"
    private let userIdKey = "ZhengHuoJu_Profile_UserId"
    private let bioKey = "ZhengHuoJu_Profile_Bio"
    private let avatarNameKey = "ZhengHuoJu_Profile_AvatarName"
    
    @Published var nickname: String {
        didSet { UserDefaults.standard.set(nickname, forKey: nicknameKey) }
    }
    
    @Published var userId: String {
        didSet { UserDefaults.standard.set(userId, forKey: userIdKey) }
    }
    
    @Published var bio: String {
        didSet { UserDefaults.standard.set(bio, forKey: bioKey) }
    }
    
    @Published var avatarName: String {
        didSet { UserDefaults.standard.set(avatarName, forKey: avatarNameKey) }
    }
    
    private init() {
        let defaults = UserDefaults.standard
        self.nickname = defaults.string(forKey: nicknameKey) ?? "整活新人"
        if let existing = defaults.string(forKey: userIdKey), !existing.isEmpty {
            self.userId = existing
        } else {
            let generated = UserProfileStore.generateUserId()
            defaults.set(generated, forKey: userIdKey)
            self.userId = generated
        }
        self.bio = defaults.string(forKey: bioKey) ?? "和朋友一起整活，好玩又有梗 ✨"
        self.avatarName = defaults.string(forKey: avatarNameKey) ?? "logo"
    }
    
    private static func generateUserId() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomChars = (0..<8).map { _ in String(chars.randomElement()!) }.joined()
        return randomChars
    }
    
    func resetIdForDebug() {
        userId = UserProfileStore.generateUserId()
    }
}
