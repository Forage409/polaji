import Foundation

final class AccountService {
    static let shared = AccountService()

    private var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "https://zhenghuo.miaogou.site"
    }

    private init() {}

    func sendCode(phone: String, purpose: String) async throws -> SMSChallengeReceipt {
        try validatePhone(phone)
        return try await publicRequest(
            path: "/api/auth/sms/send",
            body: [
                "phone": phone,
                "purpose": purpose,
                "clientInstallId": AccountSessionManager.shared.clientInstallId,
            ]
        )
    }

    func register(phone: String, code: String, challengeId: String, nickname: String, password: String, agreedToTerms: Bool) async throws -> AccountAuthReceipt {
        try validatePhone(phone)
        guard !code.isEmpty else { throw AccountAuthError.invalidCode }
        guard nickname.count >= 2 && nickname.count <= 12 else { throw AccountAuthError.invalidNickname }
        guard password.count >= 6 && password.count <= 20 else { throw AccountAuthError.invalidPassword }
        guard agreedToTerms else { throw AccountAuthError.termsRequired }
        var payload: [String: Any] = [
            "phone": phone,
            "code": code,
            "challengeId": challengeId,
            "nickname": nickname,
            "password": password,
            "agreedToTerms": true,
        ]
        if let legacy = AccountSessionManager.shared.legacyCredentials {
            payload["legacyUserId"] = legacy.userId
            payload["legacyInstallToken"] = legacy.installToken
        }
        return try await publicRequest(path: "/api/auth/register", body: payload)
    }

    func login(phone: String, code: String, challengeId: String) async throws -> AccountAuthReceipt {
        try validatePhone(phone)
        guard !code.isEmpty else { throw AccountAuthError.invalidCode }
        return try await publicRequest(
            path: "/api/auth/login",
            body: ["phone": phone, "code": code, "challengeId": challengeId]
        )
    }

    func fetchMe() async throws -> AccountProfile {
        let request = try APIClient.shared.createRequest(path: "/api/auth/me")
        let receipt: AccountProfileReceipt = try await APIClient.shared.performRequest(request: request)
        return receipt.profile
    }

    func updateProfile(nickname: String, bio: String, avatar: String) async throws -> AccountProfile {
        let body = try JSONSerialization.data(withJSONObject: [
            "nickname": nickname,
            "bio": bio,
            "avatar": avatar,
        ])
        let request = try APIClient.shared.createRequest(path: "/api/account/profile", method: "PUT", body: body)
        let receipt: AccountProfileReceipt = try await APIClient.shared.performRequest(request: request)
        return receipt.profile
    }

    func logout() async throws {
        let request = try APIClient.shared.createRequest(path: "/api/auth/logout", method: "POST")
        _ = try await APIClient.shared.performActionRequest(request: request)
    }

    func deleteAccount() async throws {
        let request = try APIClient.shared.createRequest(path: "/api/account", method: "DELETE")
        _ = try await APIClient.shared.performActionRequest(request: request)
    }

    private func validatePhone(_ phone: String) throws {
        guard phone.range(of: "^1[3-9][0-9]{9}$", options: .regularExpression) != nil else {
            throw AccountAuthError.invalidPhone
        }
    }

    private func publicRequest<T: Decodable>(path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw AccountAuthError.unavailable }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AccountAuthError.unavailable }
        if (200..<300).contains(http.statusCode) {
            guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                throw AccountAuthError.unavailable
            }
            return decoded
        }
        let errorBody = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        throw AccountAuthError.server(
            code: errorBody?["code"] as? String ?? "",
            message: errorBody?["error"] as? String ?? ""
        )
    }
}
