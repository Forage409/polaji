import Foundation
import Security

/// 匿名身份管理
/// 匿名身份会尽可能保存在设备 Keychain 中，重装后通常可以恢复；但如果系统清理 Keychain、更换设备或重置系统，可能无法恢复。
class AnonymousIdentityManager {
    static let shared = AnonymousIdentityManager()
    
    private let serviceName = "com.zhenghuoju.app.identity"
    private let idAccountName = "anonymousUserId"
    private let tokenAccountName = "installToken"
    
    private(set) var currentUserId: String = ""
    private(set) var currentInstallToken: String = ""
    
    private init() {
        initializeIdentity()
    }
    
    private func initializeIdentity() {
        let loadedId = loadFromKeychain(account: idAccountName)
        let loadedToken = loadFromKeychain(account: tokenAccountName)
        
        if let id = loadedId, let token = loadedToken {
            self.currentUserId = id
            self.currentInstallToken = token
        } else {
            // Generate new identity
            let newId = UUID().uuidString
            let newToken = UUID().uuidString
            
            saveToKeychain(account: idAccountName, value: newId)
            saveToKeychain(account: tokenAccountName, value: newToken)
            
            self.currentUserId = newId
            self.currentInstallToken = newToken
            
            // Asynchronously register the new device with the backend
            Task {
                try? await registerDevice(userId: newId, token: newToken)
            }
        }
    }
    
    private func registerDevice(userId: String, token: String) async throws {
        // We will call APIClient here, but we can't directly use APIClient's injected headers for this specific request.
        // So we do a raw request to register.
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
        guard let url = URL(string: "\(baseURL)/api/auth/device") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["anonymousUserId": userId, "installToken": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let _ = try? await URLSession.shared.data(for: request)
    }
    
    private func saveToKeychain(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

