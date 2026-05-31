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
    private var isRegistered: Bool = false

    private init() {
        initializeIdentity()
    }

    private func initializeIdentity() {
        let loadedId = loadFromKeychain(account: idAccountName)
        let loadedToken = loadFromKeychain(account: tokenAccountName)

        if let id = loadedId, let token = loadedToken {
            self.currentUserId = id
            self.currentInstallToken = token
            self.isRegistered = true  // Assume already registered if loaded from keychain
        } else {
            // Generate new identity
            let newId = UUID().uuidString
            let newToken = UUID().uuidString

            saveToKeychain(account: idAccountName, value: newId)
            saveToKeychain(account: tokenAccountName, value: newToken)

            self.currentUserId = newId
            self.currentInstallToken = newToken

            // Synchronously register the new device with the backend
            Task {
                await registerDeviceSync(userId: newId, token: newToken)
            }
        }
    }

    private func registerDeviceSync(userId: String, token: String) async {
        do {
            try await registerDevice(userId: userId, token: token)
            self.isRegistered = true
            print("Device registered successfully: \(userId)")
        } catch {
            print("Failed to register device: \(error)")
            // Retry after a delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            do {
                try await registerDevice(userId: userId, token: token)
                self.isRegistered = true
            } catch {
                print("Device registration retry failed: \(error)")
            }
        }
    }
    
    private func registerDevice(userId: String, token: String) async throws {
        // We will call APIClient here, but we can't directly use APIClient's injected headers for this specific request.
        // So we do a raw request to register.
        let baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
        guard let url = URL(string: "\(baseURL)/api/auth/device") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["anonymousUserId": userId, "installToken": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
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
