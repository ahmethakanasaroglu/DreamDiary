import Foundation

class OllamaService {
    private let baseURL = "http://localhost:11434/api/generate"
    
    func analyzeDream(content: String) async throws -> DreamAnalysis {
        // Dil algılama - basit bir heuristic ile
        let language = detectLanguage(content)
        
        // Dile göre uygun prompt seç
        let prompt = createPromptForLanguage(language, content: content)
        
        let requestBody: [String: Any] = [
            "model": "llama3",
            "prompt": prompt,
            "stream": false,
            "temperature": 0.2, // Daha tutarlı sonuçlar için düşük sıcaklık
            "top_p": 0.2 // Daha belirgin çıktılar için düşük top_p
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        print("Ollama isteği gönderiliyor (dil: \(language))...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let responseString = String(data: data, encoding: .utf8) ?? "Yanıt ayrıştırılamadı"
        print("Ollama yanıtı: \(responseString)")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OllamaError", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP yanıtı alınamadı"])
        }
        
        print("HTTP durum kodu: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            throw NSError(domain: "OllamaError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])
        }
        
        // Ollama yanıtını işle
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseContent = json["response"] as? String else {
            throw NSError(domain: "OllamaError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Json string'ini analiz et
        return try parseAnalysisFromResponse(responseContent, language: language)
    }
    
    private func detectLanguage(_ text: String) -> String {
        // Basit bir dil algılama mekanizması
        let turkishChars = Set(["ı", "ğ", "ü", "ş", "ç", "ö", "İ", "Ğ", "Ü", "Ş", "Ç", "Ö"])
        let turkishWords = Set(["bir", "ve", "ile", "bu", "çok", "için", "ama", "ben", "sen", "biz", "siz", "rüya", "gördüm", "kabus"])
        
        let lowercaseText = text.lowercased()
        
        // Türkçe karakter kontrolü
        for char in turkishChars {
            if text.contains(char) {
                return "tr"
            }
        }
        
        // Türkçe kelime kontrolü
        for word in turkishWords {
            if lowercaseText.contains(" \(word) ") || lowercaseText.starts(with: "\(word) ") || lowercaseText.contains(" \(word).") || lowercaseText == word {
                return "tr"
            }
        }
        
        // Varsayılan olarak İngilizce kabul et
        return "en"
    }
    
    private func createPromptForLanguage(_ language: String, content: String) -> String {
        switch language {
        case "tr":
            return """
            Sen profesyonel bir rüya analiz uzmanısın.

            Aşağıdaki rüya anlatımını analiz et ve şu kategorilerde bilgi ver:
            1. Temalar: Rüyanın ana temalarını belirle (örn. korku, özgürlük, kaçış)
            2. Yorumlama: Rüyanın genel bir yorumu
            3. Duygusal Ton: Rüya anlatımındaki duygu tonunu belirle
            4. Vurgulanan Öğeler: Metin içinde birden fazla kez geçen sembol veya öğeler (eğer yoksa boş bırakın)
            5. Psikolojik Perspektif: Rüyanın psikolojik açıdan yorumu

            Rüya Anlatımı: \(content)

            ÖNEMLİ: Cevabını TAMAMEN TÜRKÇE olarak ver, hiçbir İngilizce kelime kullanma.
            Bütün kategorilere mutlaka cevap ver ve boş bırakma.
            
            Yanıtını JSON formatında ver, sadece şu şekilde:
            {
              "themes": ["tema1", "tema2", ...],
              "interpretation": "Yorumlama metni",
              "emotionalTone": "Duygusal ton tanımı",
              "recurringElements": ["öğe1", "öğe2", ...],
              "psychologicalPerspective": "Psikolojik perspektif açıklaması"
            }
            """
        default: // İngilizce veya diğer diller için
            return """
            You are a professional dream analyst.

            Analyze the following dream and provide information in these categories:
            1. Themes: Identify the main themes of the dream (e.g., fear, freedom, escape)
            2. Interpretation: A general interpretation of the dream
            3. Emotional Tone: Identify the emotional tone in the dream narrative
            4. Recurring Elements: Recurring symbols or elements, if any
            5. Psychological Perspective: Psychological perspective of the dream

            Dream Narrative: \(content)

            IMPORTANT: Give your answer COMPLETELY IN ENGLISH, do not use any other language.
            Be sure to answer all categories and don't leave any blank.
            
            Provide your answer in JSON format, exactly as follows:
            {
              "themes": ["theme1", "theme2", ...],
              "interpretation": "Interpretation text",
              "emotionalTone": "Emotional tone description",
              "recurringElements": ["element1", "element2", ...],
              "psychologicalPerspective": "Psychological perspective description"
            }
            """
        }
    }
    
    private func parseAnalysisFromResponse(_ content: String, language: String) throws -> DreamAnalysis {
        print("API yanıtını ayrıştırma: \(content)")
        
        // İlk ve son JSON ayraçlarını bul
        if let jsonStartIndex = content.range(of: "{")?.lowerBound,
           let jsonEndIndex = content.range(of: "}", options: .backwards)?.upperBound {
            
            let jsonContent = String(content[jsonStartIndex..<jsonEndIndex])
            
            if let data = jsonContent.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(DreamAnalysis.self, from: data)
                } catch {
                    print("JSON ayrıştırma hatası: \(error)")
                }
            }
        }
        
        // Ayrıştırma başarısız olursa manuel ayrıştırma dene
        var analysis = DreamAnalysis()
        
        // Dile göre uygun anahtar kelimeler
        let (themesKey, interpretationKey, emotionalToneKey, recurringElementsKey, psychologicalPerspectiveKey) =
            language == "tr" ?
                ("themes", "interpretation", "emotionalTone", "recurringElements", "psychologicalPerspective") :
                ("themes", "interpretation", "emotionalTone", "recurringElements", "psychologicalPerspective")
        
        // Basit regex ile ayrıştırma yapmayı dene
        if let themesMatch = try? content.match(regex: "\"\(themesKey)\"\\s*:\\s*\\[(.*?)\\]"),
           let themes = themesMatch.first {
            analysis.themes = themes.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.replacingOccurrences(of: "\"", with: "") }
                .filter { !$0.isEmpty }
        } else {
            analysis.themes = language == "tr" ? ["Analiz edilemedi"] : ["Could not be analyzed"]
        }
        
        if let interpretationMatch = try? content.match(regex: "\"\(interpretationKey)\"\\s*:\\s*\"(.*?)\""),
           let interpretation = interpretationMatch.first {
            analysis.interpretation = interpretation.replacingOccurrences(of: "\"", with: "")
        } else {
            analysis.interpretation = language == "tr" ? "Yorumlama yapılamadı" : "Could not be interpreted"
        }
        
        if let toneMatch = try? content.match(regex: "\"\(emotionalToneKey)\"\\s*:\\s*\"(.*?)\""),
           let tone = toneMatch.first {
            analysis.emotionalTone = tone.replacingOccurrences(of: "\"", with: "")
        } else {
            analysis.emotionalTone = language == "tr" ? "Belirsiz" : "Uncertain"
        }
        
        if let elementsMatch = try? content.match(regex: "\"\(recurringElementsKey)\"\\s*:\\s*\\[(.*?)\\]"),
           let elements = elementsMatch.first {
            analysis.recurringElements = elements.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.replacingOccurrences(of: "\"", with: "") }
                .filter { !$0.isEmpty }
        } else {
            analysis.recurringElements = language == "tr" ? ["Analiz edilemedi"] : ["Could not be analyzed"]
        }
        
        if let perspectiveMatch = try? content.match(regex: "\"\(psychologicalPerspectiveKey)\"\\s*:\\s*\"(.*?)\""),
           let perspective = perspectiveMatch.first {
            analysis.psychologicalPerspective = perspective.replacingOccurrences(of: "\"", with: "")
        } else {
            analysis.psychologicalPerspective = language == "tr" ? "Analiz edilemedi" : "Could not be analyzed"
        }
        
        // Eğer Türkçe içerik için İngilizce cevap verildiyse otomatik çeviri yap
        if language == "tr" && containsEnglish(analysis) {
            return translateToTurkish(analysis)
        }
        
        // Eğer İngilizce içerik için Türkçe cevap verildiyse otomatik çeviri yap
        if language == "en" && containsTurkish(analysis) {
            return translateToEnglish(analysis)
        }
        
        return analysis
    }
    
    // İngilizce kelime içeriyor mu kontrol et
    private func containsEnglish(_ analysis: DreamAnalysis) -> Bool {
        let englishWords = ["dream", "fear", "freedom", "escape", "anxiety", "happiness", "sadness", "family", "death", "journey", "water", "fire"]
        
        // Analiz içinde İngilizce anahtar kelimeler var mı kontrol et
        for word in englishWords {
            if analysis.interpretation.lowercased().contains(word) ||
               analysis.emotionalTone.lowercased().contains(word) ||
               analysis.psychologicalPerspective.lowercased().contains(word) ||
               analysis.themes.joined(separator: " ").lowercased().contains(word) ||
               analysis.recurringElements.joined(separator: " ").lowercased().contains(word) {
                return true
            }
        }
        return false
    }
    
    // Türkçe kelime içeriyor mu kontrol et
    private func containsTurkish(_ analysis: DreamAnalysis) -> Bool {
        let turkishWords = ["rüya", "korku", "özgürlük", "kaçış", "kaygı", "mutluluk", "üzüntü", "aile", "ölüm", "yolculuk", "su", "ateş"]
        
        // Analiz içinde Türkçe anahtar kelimeler var mı kontrol et
        for word in turkishWords {
            if analysis.interpretation.lowercased().contains(word) ||
               analysis.emotionalTone.lowercased().contains(word) ||
               analysis.psychologicalPerspective.lowercased().contains(word) ||
               analysis.themes.joined(separator: " ").lowercased().contains(word) ||
               analysis.recurringElements.joined(separator: " ").lowercased().contains(word) {
                return true
            }
        }
        return false
    }
    
    // İngilizceden Türkçeye temel çeviri
    private func translateToTurkish(_ analysis: DreamAnalysis) -> DreamAnalysis {
        let translations: [String: String] = [
            "fear": "korku",
            "anxiety": "kaygı",
            "freedom": "özgürlük",
            "escape": "kaçış",
            "happiness": "mutluluk",
            "joy": "sevinç",
            "sadness": "üzüntü",
            "family": "aile",
            "death": "ölüm",
            "water": "su",
            "fire": "ateş",
            "dream": "rüya",
            "nightmare": "kabus",
            "positive": "olumlu",
            "negative": "olumsuz",
            "emotions": "duygular",
            "symbols": "semboller",
            "analysis": "analiz",
            "psychological": "psikolojik",
            "this dream": "bu rüya",
            "highlighted": "vurgulanan",
            "elements": "öğeler"
        ]
        
        var translated = analysis
        
        // Çeviriyi uygula
        for (english, turkish) in translations {
            translated.interpretation = translated.interpretation.replacingOccurrences(of: english, with: turkish, options: .caseInsensitive)
            translated.emotionalTone = translated.emotionalTone.replacingOccurrences(of: english, with: turkish, options: .caseInsensitive)
            translated.psychologicalPerspective = translated.psychologicalPerspective.replacingOccurrences(of: english, with: turkish, options: .caseInsensitive)
            
            translated.themes = translated.themes.map { $0.replacingOccurrences(of: english, with: turkish, options: .caseInsensitive) }
            translated.recurringElements = translated.recurringElements.map { $0.replacingOccurrences(of: english, with: turkish, options: .caseInsensitive) }
        }
        
        return translated
    }
    
    // Türkçeden İngilizceye temel çeviri
    private func translateToEnglish(_ analysis: DreamAnalysis) -> DreamAnalysis {
        let translations: [String: String] = [
            "korku": "fear",
            "kaygı": "anxiety",
            "özgürlük": "freedom",
            "kaçış": "escape",
            "mutluluk": "happiness",
            "sevinç": "joy",
            "üzüntü": "sadness",
            "aile": "family",
            "ölüm": "death",
            "su": "water",
            "ateş": "fire",
            "rüya": "dream",
            "kabus": "nightmare",
            "olumlu": "positive",
            "olumsuz": "negative",
            "duygular": "emotions",
            "semboller": "symbols",
            "analiz": "analysis",
            "psikolojik": "psychological",
            "bu rüya": "this dream",
            "vurgulanan": "highlighted",
            "öğeler": "elements"
        ]
        
        var translated = analysis
        
        // Çeviriyi uygula
        for (turkish, english) in translations {
            translated.interpretation = translated.interpretation.replacingOccurrences(of: turkish, with: english, options: .caseInsensitive)
            translated.emotionalTone = translated.emotionalTone.replacingOccurrences(of: turkish, with: english, options: .caseInsensitive)
            translated.psychologicalPerspective = translated.psychologicalPerspective.replacingOccurrences(of: turkish, with: english, options: .caseInsensitive)
            
            translated.themes = translated.themes.map { $0.replacingOccurrences(of: turkish, with: english, options: .caseInsensitive) }
            translated.recurringElements = translated.recurringElements.map { $0.replacingOccurrences(of: turkish, with: english, options: .caseInsensitive) }
        }
        
        return translated
    }
}

// Regex yardımcı metodu
extension String {
    func match(regex pattern: String) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return results.compactMap { result -> String? in
            if result.numberOfRanges > 1 {
                let range = result.range(at: 1)
                if range.location != NSNotFound {
                    return nsString.substring(with: range)
                }
            }
            return nil
        }
    }
}
