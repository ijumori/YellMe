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

                    profileEditSection
                    avatarSection
                    subscriptionSection

                    #if DEBUG
                    developerPlanSection
                    developerKeychainSection
                    #endif
                }
            }
            .navigationTitle("マイページ")
            .task {
                await viewModel.fetchData(appState: appState)
            }
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
                set: { appState.debugOverrideSubscriptionTier($0) }
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

    private var profileEditSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プロフィール編集")
                .font(.headline)

            TextField("表示名", text: $viewModel.displayName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("自己紹介（任意）", text: $viewModel.bio, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)

            if let message = viewModel.message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(viewModel.messageIsError ? .red : .secondary)
            }

            Button {
                Task {
                    await viewModel.saveProfile(appState: appState)
                }
            } label: {
                HStack {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Label("保存", systemImage: "square.and.arrow.down")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSave || viewModel.isSaving)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

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
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var isSaving = false
    @Published var message: String?
    @Published var messageIsError = false

    var canSave: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 30 && bio.count <= 160
    }

    func fetchData(appState: AppState) async {
        message = nil
        messageIsError = false

        guard appState.isFirebaseConfigured, let uid = appState.authUser?.uid else {
            // Firebase未設定のローカルモードでも編集欄は使えるように初期値を置く
            if displayName.isEmpty {
                displayName = "わたし"
            }
            return
        }

        do {
            if let fetched = try await FirebaseService.shared.fetchUser(id: uid) {
                user = fetched
            } else {
                user = User(id: uid, displayName: "わたし", bio: "", profileImageURL: nil, createdAt: .now)
            }

            if let current = user {
                displayName = current.displayName
                bio = current.bio
            }
        } catch {
            message = "プロフィールの取得に失敗しました。"
            messageIsError = true
        }
    }

    func saveProfile(appState: AppState) async {
        guard canSave else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        // ローカルモードは画面上だけの保存として扱う
        guard appState.isFirebaseConfigured, let uid = appState.authUser?.uid else {
            user = User(
                id: user?.id ?? "local-user",
                displayName: trimmedName,
                bio: trimmedBio,
                profileImageURL: user?.profileImageURL,
                createdAt: user?.createdAt ?? .now
            )
            message = "保存しました（ローカルモード）"
            messageIsError = false
            return
        }

        isSaving = true
        message = nil
        defer { isSaving = false }

        do {
            let newUser = User(
                id: uid,
                displayName: trimmedName,
                bio: trimmedBio,
                profileImageURL: user?.profileImageURL,
                createdAt: user?.createdAt ?? .now
            )
            try await FirebaseService.shared.saveUser(newUser)
            user = newUser
            message = "保存しました。"
            messageIsError = false
        } catch {
            message = "保存に失敗しました。時間をおいて再試行してください。"
            messageIsError = true
        }
    }
}
