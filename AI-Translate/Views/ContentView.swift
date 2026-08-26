import SwiftUI

struct ContentView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @EnvironmentObject var translationService: TranslationService
    @EnvironmentObject var floatingWindow: FloatingWindowManager

    @State private var showSettings = false
    @State private var showFloating = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.black, Color(hex: "#1a1a2e")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // 状态
                    Text(speechManager.isRecording ? "正在聆听..." : "点击麦克风开始说话")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(speechManager.isRecording ? Color.red : Color.gray)

                    // 识别的日文
                    if !speechManager.recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("识别结果（日文）")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                            Text(speechManager.recognizedText)
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundStyle(Color.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                    }

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

                    // 麦克风按钮
                    Button(action: toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isRecording ? Color.red : Color(hex: "#02D7E0"))
                                .frame(width: 100, height: 100)
                                .shadow(radius: speechManager.isRecording ? 20 : 10, x: 0, y: 0)

                            Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                    }
                    .scaleEffect(speechManager.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: speechManager.isRecording)

                    // 悬浮窗按钮
                    HStack(spacing: 20) {
                        Button(action: {
                            floatingWindow.toggle(text: translationService.translatedText)
                            showFloating.toggle()
                        }) {
                            Label(showFloating ? "关闭悬浮窗" : "开启悬浮窗", systemImage: "pip.enter")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(showFloating ? .red : Color(hex: "#02D7E0"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }

                        Button(action: { showSettings = true }) {
                            Label("设置", systemImage: "gearshape")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .navigationTitle("AI 翻译")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("设置") { showSettings = true }
                            .foregroundStyle(Color(hex: "#02D7E0"))
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
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
