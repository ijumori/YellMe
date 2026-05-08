import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [Color.pink.opacity(0.12), Color.orange.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ロゴ
                VStack(spacing: 12) {
                    Text("💛")
                        .font(.system(size: 80))

                    Text("エールミー")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("日記を書くと、AIが必ず\n褒めポイントを見つけてくれる")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("最短30秒で、今日の記録が残せます")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // キャッチコピー3点
                VStack(spacing: 16) {
                    FeatureRow(icon: "sparkles", text: "批判ゼロ、共感100%の優しい世界")
                    FeatureRow(icon: "bubble.left.and.bubble.right", text: "4つのモードで寄り添うAIフィードバック")
                    FeatureRow(icon: "book.closed.fill", text: "自分だけの記録として安心して続けられる")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // サインインボタン
                VStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            viewModel.prepareRequest(request)
                        } onCompletion: { result in
                            Task { await viewModel.handleCompletion(result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Text("ログインすると利用規約とプライバシーポリシーに同意したとみなします")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.pink)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var pendingNonce: String?

    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        Task {
            let nonce = await AuthService.shared.makeNonce()
            let hashedNonce = await AuthService.shared.sha256(nonce)
            pendingNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce
        }
    }

    func handleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            let nsError = error as NSError
            // キャンセルはエラー扱いしない
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue { return }
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = appleCredential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = AuthError.missingToken.localizedDescription
                return
            }
            guard let nonce = pendingNonce else {
                errorMessage = AuthError.missingNonce.localizedDescription
                return
            }

            isLoading = true
            defer { isLoading = false }

            do {
                _ = try await AuthService.shared.signInWithApple(
                    idToken: idToken,
                    rawNonce: nonce,
                    fullName: appleCredential.fullName
                )
                // AppState の auth listener が自動で状態を更新する
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
}
