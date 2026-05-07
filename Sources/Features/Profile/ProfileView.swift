import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    #if DEBUG
    @State private var showKeychainDevAlert = false
    @State private var keychainDevAlertText = ""
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールヘッダー
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.pink)
                            )
                        Text(viewModel.user?.displayName ?? "名前未設定")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if let bio = viewModel.user?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()

                    Text("日記の一覧は「きろく」タブから見られます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    avatarSection
                    subscriptionSection

                    #if DEBUG
                    developerPlanSection
                    developerKeychainSection
                    #endif
                }
            }
            .navigationTitle("マイページ")
            #if DEBUG
            .alert("開発用", isPresented: $showKeychainDevAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(keychainDevAlertText)
            }
            #endif
        }
    }

    #if DEBUG
    @ViewBuilder
    private var developerPlanSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("開発（プラン切替）")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("プラン", selection: Binding(
                get: { appState.subscriptionTier },
                set: { appState.setSubscriptionTier($0) }
            )) {
                Text("Free").tag(SubscriptionTier.free)
                Text("Premium").tag(SubscriptionTier.premium)
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.pink.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var developerKeychainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("開発（Keychain）")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Secrets のキーをキーチェーンに保存") {
                switch ClaudeAPIKeyStore.saveCurrentSecretsKeyToKeychain() {
                case .success:
                    keychainDevAlertText = "保存しました。Secrets.swift のキーは手動でプレースホルダーに戻すと、Keychain 優先で安全側になります。"
                case .rejectedPlaceholder:
                    keychainDevAlertText = "プレースホルダーは保存できません。先に Secrets.swift に実キーを設定してください。"
                case .keychainError:
                    keychainDevAlertText = "Keychain への保存に失敗しました。"
                }
                showKeychainDevAlert = true
            }
            .buttonStyle(.bordered)

            Button("キーチェーンのキーを削除", role: .destructive) {
                _ = ClaudeAPIKeyStore.deleteKey()
                keychainDevAlertText = "キーチェーンから削除しました。"
                showKeychainDevAlert = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    #endif

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("アバター")
                    .font(.headline)
                Spacer()
                Text(appState.subscriptionTier == .premium ? "着せ替え可" : "基本装備")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                // 課金プラン導線は次段で実装
            } label: {
                Label(
                    appState.planFeatures.canCustomizeAvatar ? "着せ替えを開く" : "着せ替えはPremiumで利用可能",
                    systemImage: appState.planFeatures.canCustomizeAvatar ? "tshirt.fill" : "lock.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)
            .disabled(!appState.planFeatures.canCustomizeAvatar)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("プラン")
                    .font(.headline)
                Spacer()
                Text(appState.subscriptionTier == .premium ? "Premium" : "Free")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.15))
                    .clipShape(Capsule())
            }

            if let message = appState.billingMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if appState.subscriptionTier != .premium {
                Button {
                    Task { await appState.purchasePremium() }
                } label: {
                    Label("Premiumにアップグレード", systemImage: "crown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isBillingBusy)
            }

            Button {
                Task { await appState.restorePurchases() }
            } label: {
                Label("購入を復元", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(appState.isBillingBusy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?

    func fetchData() async {
        // TODO: Firestore からフェッチ
    }
}
