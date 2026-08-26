import SwiftUI

struct ContentView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var floatingWindow: FloatingWindowManager

    @State private var showSettings = false
    @State private var inputText = ""
    @State private var showPiP = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.black, Color(hex: "#1a1a2e")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // 翻译结果
                    if !translationService.translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("翻译结果（中文）")
                                .font(.caption)
                                .foregroundStyle(Color.cyan)
                            Text(translationService.translatedText)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.cyan)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.cyan.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                    }

                    // 粘贴日语字幕输入
                    VStack(alignment: .leading, spacing: 10) {
                        Text("粘贴日语字幕 / 文本，翻译后显示在系统画中画")
                            .font(.caption)
                            .foregroundStyle(Color.gray)

                        TextEditor(text: $inputText)
                            .frame(height: 130)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.05))
                            .foregroundStyle(Color.white)
                            .font(.system(size: 16))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                        Button(action: translateAndShow) {
                            HStack {
                                if translationService.isTranslating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "pip")
                                }
                                Text(translationService.isTranslating ? "翻译中..." : "翻译并显示到画中画")
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.white.opacity(0.1) : Color(hex: "#02D7E0"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || translationService.isTranslating)
                    }
                    .padding(.horizontal, 24)

                    // 控制区
                    HStack(spacing: 20) {
                        // 麦克风（次要功能）
                        Button(action: toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(speechManager.isRecording ? Color.red : Color(hex: "#02D7E0"))
                                    .frame(width: 64, height: 64)
                                    .shadow(radius: speechManager.isRecording ? 16 : 6)
                                Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.white)
                            }
                        }
                        .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: speechManager.isRecording)

                        // 画中画开关
                        Button(action: {
                            if floatingWindow.isShowing {
                                floatingWindow.hide()
                            } else {
                                floatingWindow.show(text: translationService.translatedText)
                            }
                            showPiP = floatingWindow.isShowing
                        }) {
                            Label(floatingWindow.isShowing ? "关闭画中画" : "开启画中画", systemImage: "pip.enter")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(floatingWindow.isShowing ? .red : Color(hex: "#02D7E0"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }

                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.gray)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .navigationTitle("AI 翻译")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
        }
        .onReceive(translationService.$translatedText) { newText in
            // 画中画开启时，实时同步最新翻译结果
            if floatingWindow.isShowing, !newText.isEmpty {
                floatingWindow.updateText(newText)
            }
        }
    }

    private func translateAndShow() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await translationService.translate(trimmed)
            // 翻译完成后，若已有旧结果先保证显示；或手动开画中画
        }
    }

    private func toggleRecording() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            speechManager.startRecording { text in
                if !text.isEmpty {
                    Task { await translationService.translate(text) }
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    ContentView()
        .environmentObject(SpeechManager())
        .environmentObject(TranslationService())
        .environmentObject(FloatingWindowManager())
}