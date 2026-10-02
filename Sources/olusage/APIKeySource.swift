import Foundation
import OlusageCore
import Security

/// Stores the optional Ollama API key in the login Keychain (never on disk in plain text).
enum KeyStore {
    private static let service = "olusage.ollama-api-key"
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
    }

    static func load() -> String? {
        var q = query
        q[kSecReturnData as String] = true
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ key: String) {
        SecItemDelete(query as CFDictionary)
        var q = query
        q[kSecValueData as String] = Data(key.utf8)
        SecItemAdd(q as CFDictionary, nil)
    }

    static func delete() { SecItemDelete(query as CFDictionary) }
}

/// Reads usage from the undocumented `GET https://ollama.com/api/usage` with a Bearer API key.
/// Sturdier than scraping, but has no reset times.
@MainActor
final class APIKeySource: UsageSource {
    enum APIError: Error { case http(Int) }
    static let endpoint = URL(string: "https://ollama.com/api/usage")!

    private let apiKey: String
    init(apiKey: String) { self.apiKey = apiKey }

    func fetchUsage() async throws -> Usage {
        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
            if status == 401 || status == 403 { throw ParseError.signedOut }   // bad/revoked key
            throw APIError.http(status)
        }
        return try APIUsageParser.parse(data: data)
    }
}
