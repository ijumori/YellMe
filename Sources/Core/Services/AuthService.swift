import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

actor AuthService {
    static let shared = AuthService()

    // MARK: - Apple Sign In

    /// Apple Sign In 用の nonce を生成して保持する（ViewModel 側に渡す）
    func makeNonce() -> String {
        randomNonceString()
    }

    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Apple 認証完了後に Firebase にサインイン
    func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: PersonNameComponents?
    ) async throws -> FirebaseAuth.User {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        let result = try await Auth.auth().signIn(with: credential)
        return result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    // MARK: - Private

    private func randomNonceString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }
}

enum AuthError: Error, LocalizedError {
    case missingToken
    case missingNonce

    var errorDescription: String? {
        switch self {
        case .missingToken: return "Apple の認証トークンを取得できませんでした"
        case .missingNonce: return "セキュリティコードが見つかりません"
        }
    }
}
