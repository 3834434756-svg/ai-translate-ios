# AI 翻译 - iOS 日语实时翻译悬浮窗

基于 SwiftUI + iOS 原生 API 的日语实时语音翻译 App，支持画中画悬浮窗显示翻译结果。无需越狱，纯合规开发。

## 功能

- 🎤 **日语语音识别**：基于 `Speech` 框架，实时日语转文字
- 🌐 **AI 翻译**：预置多接口（MyMemory / LibreTranslate / OpenAI / DeepL），默认免费接口无需 Key 即可使用，也可自行填入 Key 换取更高质量翻译
- 🪟 **悬浮窗显示**：翻译结果在悬浮窗中展示，不影响当前操作
- 📱 **iOS 16.0+**

## 构建

### 方式一：GitHub Actions 自动构建（推荐）

Push 到 GitHub 后，Actions 会自动在 macOS 上编译出 `.ipa`，在 Actions 页面下载即可。

### 方式二：本地 Xcode 构建

```bash
# 1. 用 Xcode 打开 AI-Translate.xcodeproj
open AI-Translate.xcodeproj

# 2. 修改 Bundle Identifier（如需）
# 3. 选择任意 Team（或 Personal Team），关闭自动签名
# 4. Product → Archive → Export IPA
```

## 安装

- 使用 **AltStore** / **SideStore**  sideload 安装生成的 IPA
- 或使用 Xcode 直接运行到设备

## 隐私

- 麦克风与语音识别数据仅在本地处理
- 翻译文本会发送到所选翻译接口（MyMemory / LibreTranslate / OpenAI / DeepL）
- 不会收集或上传任何个人数据

## License

MIT
