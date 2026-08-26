import Foundation
import Combine

enum TranslationProvider: String, CaseIterable {
    case myMemory = "MyMemory"
    case libreTranslate = "LibreTranslate"
    case openAI = "OpenAI"
    case deepL = "DeepL"

    var displayName: String { rawValue }
    var requiresKey: Bool {
        switch self {
        case .myMemory, .libreTranslate: return false
        case .openAI, .deepL: return true
        }
    }
}

@MainActor
class TranslationService: ObservableObject {
    @Published var translatedText = ""
    @Published var isTranslating = false
    @Published var lastError: String?

    var apiKey: String = ""
    var selectedProvider: TranslationProvider = .myMemory
    var customEndpoint: String = ""
    var customModel: String = "gpt-4o-mini"

    private let session = URLSession.shared

    func translate(_ text: String) async {
        guard !text.isEmpty else { return }
        isTranslating = true
        lastError = nil

        let sourceLang = "ja"
        let targetLang = "zh-CN"

        let result: String?
        switch selectedProvider {
        case .myMemory:
            result = await translateWithMyMemory(text, source: sourceLang, target: targetLang)
        case .libreTranslate:
            result = await translateWithLibreTranslate(text, source: sourceLang, target: targetLang)
        case .openAI:
            result = await translateWithOpenAI(text, source: sourceLang, target: targetLang)
        case .deepL:
            result = await translateWithDeepL(text, source: sourceLang, target: targetLang)
        }

        translatedText = result ?? "翻译失败"
        isTranslating = false
    }

    // MARK: - MyMemory (免费，无需 Key)
    private func translateWithMyMemory(_ text: String, source: String, target: String) async -> String? {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let urlString = "https://api.mymemory.translated.net/get?q=\(encoded)&langpair=\(source)|\(target)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            let json = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
            return json.responseData.translatedText
        } catch {
            lastError = "MyMemory: \(error.localizedDescription)"
            return nil
        }
    }

    private struct MyMemoryResponse: Codable {
        let responseData: ResponseData
        struct ResponseData: Codable {
            let translatedText: String
        }
    }

    // MARK: - LibreTranslate (免费公共实例)
    private func translateWithLibreTranslate(_ text: String, source: String, target: String) async -> String? {
        let endpoints = [
            "https://libretranslate.de",
            "https://translate.argosopentech.com",
            "https://libretranslate.pussthecat.org"
        ]
        for endpoint in endpoints {
            guard let url = URL(string: "\(endpoint)/translate") else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body = [
                "q": text,
                "source": source,
                "target": target,
                "format": "text"
            ] as [String: Any]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (data, _) = try await session.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let translated = json?["translatedText"] as? String { return translated }
            } catch { continue }
        }
        lastError = "LibreTranslate: 所有实例均不可用"
        return nil
    }

    // MARK: - OpenAI 兼容接口
    private func translateWithOpenAI(_ text: String, source: String, target: String) async -> String? {
        guard !apiKey.isEmpty else {
            lastError = "OpenAI: 未配置 API Key"
            return nil
        }
        let endpoint = customEndpoint.isEmpty ? "https://api.openai.com/v1/chat/completions" : customEndpoint
        guard let url = URL(string: endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let prompt = "将以下日文翻译成简体中文，只输出翻译结果，不要额外解释：\n\(text)"
        let body: [String: Any] = [
            "model": customModel,
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 500,
            "temperature": 0.3
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await session.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let choices = json?["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            lastError = "OpenAI: \(error.localizedDescription)"
        }
        return nil
    }

    // MARK: - DeepL
    private func translateWithDeepL(_ text: String, source: String, target: String) async -> String? {
        guard !apiKey.isEmpty else {
            lastError = "DeepL: 未配置 API Key"
            return nil
        }
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params = [
            "auth_key": apiKey,
            "text": text,
            "source_lang": source.uppercased(),
            "target_lang": target.replacingOccurrences(of: "-", with: "").uppercased()
        ]
        let bodyString = params.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        do {
            let (data, _) = try await session.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let translations = json?["translations"] as? [[String: Any]],
               let text = translations.first?["text"] as? String {
                return text
            }
        } catch {
            lastError = "DeepL: \(error.localizedDescription)"
        }
        return nil
    }
}
