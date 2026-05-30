import Foundation
import Security

class AnonymousIdentityManager {
    static let shared = AnonymousIdentityManager()
    
    private let serviceName = "com.zhenghuoju.app.identity"
    private let accountName = "anonymousUserId"
    
    // Returns the UUID from Keychain, creating it if it doesn't exist
    var currentUserId: String {
        if let existingId = loadFromKeychain() {
            return existingId
        }
        let newId = UUID().uuidString
        saveToKeychain(id: newId)
        return newId
    }
    
    private init() {}
    
    private func saveToKeychain(id: String) {
        let data = Data(id.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
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
