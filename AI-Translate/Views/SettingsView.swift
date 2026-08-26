import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var translationService: TranslationService

    @State private var selectedProvider: TranslationProvider = .myMemory
    @State private var apiKey: String = ""
    @State private var customEndpoint: String = ""
    @State private var customModel: String = "gpt-4o-mini"
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("翻译引擎") {
                    Picker("引擎", selection: $selectedProvider) {
                        ForEach(TranslationProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("当前引擎：\(selectedProvider.displayName)\(selectedProvider.requiresKey ? "（需要配置 Key）" : "（免费，无需 Key）")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if selectedProvider.requiresKey {
                    Section("API 配置") {
                        TextField("API Key", text: $apiKey)
                            .textContentType(.password)
                            .autocorrectionDisabled()

                        TextField("接口地址（可选）", text: $customEndpoint)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        TextField("模型名称", text: $customModel)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("关于") {
                    Text("AI 翻译 v1.0\n基于免费翻译接口，支持日语实时翻译。悬浮窗可显示翻译结果。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        translationService.selectedProvider = selectedProvider
                        translationService.apiKey = apiKey
                        translationService.customEndpoint = customEndpoint
                        translationService.customModel = customModel
                        toastMessage = "已保存"
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    Text(toastMessage)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                selectedProvider = translationService.selectedProvider
                apiKey = translationService.apiKey
                customEndpoint = translationService.customEndpoint
                customModel = translationService.customModel
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TranslationService())
}
