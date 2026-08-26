import SwiftUI

struct ContentView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var floatingWindow: FloatingWindowManager
    @EnvironmentObject var bridge: SubtitleBridge

    @State private var showSettings = false
    @State private var urlText = ""
    @State private var currentURL: URL
    @State private var pipActive = false

    init() {
        // 默认打开油管首页；用户在地址栏贴具体视频链接
        let defaultURL = URL(string: "https://www.youtube.com")!
        _currentURL = State(initialValue: defaultURL)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 地址栏：贴油管视频链接
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(Color(hex: "#02D7E0"))
                    TextField("粘贴油管视频/直播链接，点前往", text: $urlText)
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .onSubmit { navigate() }
                    Button(action: navigate) {
                        Text("前往")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#02D7E0"))
                            .foregroundStyle(.black)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 12)
                .padding(.top, 6)

                // 油管播放页（可登录，字幕注入）
                YouTubePlayerView(bridge: bridge, translationService: translationService, homeURL: currentURL)
                    .ignoresSafeArea(edges: .bottom)

                // 翻译叠加层（显示当前字幕 + 中文）
                if !bridge.translatedSubtitle.isEmpty || !bridge.currentSubtitle.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !bridge.currentSubtitle.isEmpty {
                            Text(bridge.currentSubtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                        Text(bridge.translatedSubtitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.cyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.7))
                    .overlay(alignment: .topTrailing) {
                        Button(action: { bridge.reset() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("AI 翻译 · 油管字幕")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if floatingWindow.isShowing {
                            floatingWindow.hide()
                        } else {
                            floatingWindow.show(text: bridge.translatedSubtitle.isEmpty ? "字幕翻译" : bridge.translatedSubtitle)
                        }
                    } label: {
                        Image(systemName: floatingWindow.isShowing ? "pip.exit" : "pip.enter")
                            .foregroundStyle(floatingWindow.isShowing ? Color.red : Color(hex: "#02D7E0"))
                    }
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color(hex: "#02D7E0"))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                // 有最新翻译时，若画中画开启则同步
            }
            .onReceive(floatingWindow.$isShowing) { isShowing in
                pipActive = isShowing
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { pipActive = floatingWindow.isShowing }
    }

    private func navigate() {
        let raw = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        if let url = URL(string: raw) {
            currentURL = url
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SpeechManager())
        .environmentObject(TranslationService())
        .environmentObject(FloatingWindowManager())
        .environmentObject(SubtitleBridge(floatingWindow: FloatingWindowManager(), translationService: TranslationService()))
}