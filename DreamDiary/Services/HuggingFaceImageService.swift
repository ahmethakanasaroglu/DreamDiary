import Foundation
import UIKit

class HuggingFaceImageService {
    private let token: String
    private let baseURL = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-3.5-large"
    
    init(token: String) {
        self.token = token
    }
    
    func generateImage(fromPrompt prompt: String) async throws -> String {
        print("Hugging Face API görsel oluşturma başlatılıyor")
        
        // Rüya içeriğinden anahtar kelimeleri çıkar
        let keywords = extractKeywords(from: prompt)
        
        // Gelişmiş bir prompt oluştur
        let enhancedPrompt = buildDreamPrompt(content: prompt, keywords: keywords)
        
        print("Geliştirilmiş prompt: \(enhancedPrompt)")
        
        // JSON formatında istek gövdesi oluştur
        let requestBody: [String: Any] = [
            "inputs": enhancedPrompt,
            "parameters": [
                "negative_prompt": "blurry, bad quality, distorted, ugly, unrealistic proportions, bad anatomy, low resolution, text, watermark, cartoon style, anime style",
                "guidance_scale": 9.0,
                "num_inference_steps": 50,
                "seed": Int.random(in: 1...9999999)
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // İstek gönder ve yanıt bekle
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HuggingFaceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP yanıtı alınamadı"])
        }
        
        print("HTTP durum kodu: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HuggingFaceError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Yanıt doğrudan görsel verisi (binary) olacaktır
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "HuggingFaceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data in response"])
        }
        
        // Görüntüyü dosya sistemine kaydet
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            try imageData.write(to: fileURL)
            return fileURL.absoluteString
        } else {
            throw NSError(domain: "HuggingFaceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG"])
        }
    }
    
    // Metinden anahtar kelimeleri çıkar
    private func extractKeywords(from text: String) -> [String] {
        // Basit bir yaklaşım: Metni kelimelere böl, kısa kelimeleri ve yaygın stopword'leri filtrele
        let stopwords = ["ve", "ile", "bir", "bu", "da", "de", "için", "gibi", "çok", "kadar", "sonra", "önce"]
        
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !stopwords.contains($0) }
        
        // Benzersiz anahtar kelimeleri ve metinde birden fazla geçen kelimeleri bul
        var wordCount: [String: Int] = [:]
        for word in words {
            wordCount[word, default: 0] += 1
        }
        
        // En çok geçen ve potansiyel olarak önemli kelimeleri döndür
        return Array(wordCount.keys)
            .filter { wordCount[$0]! >= 1 } // Tekrar eden kelimeler daha önemli olabilir
            .prefix(6) // En önemli 6 kelimeye odaklan
            .map { $0 } // ArraySlice'ı Array'e dönüştür
    }
    
    // Rüya içeriğinden görsel prompt oluştur
    private func buildDreamPrompt(content: String, keywords: [String]) -> String {
        // Anahtar kelimeleri vurgula
        let keywordEmphasis = keywords.joined(separator: ", ")
        
        // Metin içinde duygu analizi
        let emotionalTone: String
        let lowercaseContent = content.lowercased()
        
        if lowercaseContent.contains("korku") || lowercaseContent.contains("kabus") || lowercaseContent.contains("ürkütücü") {
            emotionalTone = "dark, ominous, haunting, nightmare, scary"
        } else if lowercaseContent.contains("mutlu") || lowercaseContent.contains("sevinç") || lowercaseContent.contains("güzel") {
            emotionalTone = "happy, peaceful, serene, pleasant, beautiful"
        } else if lowercaseContent.contains("tuhaf") || lowercaseContent.contains("garip") || lowercaseContent.contains("acayip") {
            emotionalTone = "surreal, bizarre, strange, odd, unsettling"
        } else if lowercaseContent.contains("uçmak") || lowercaseContent.contains("uçuyorum") || lowercaseContent.contains("özgür") {
            emotionalTone = "floating, weightless, freedom, flying, soaring"
        } else {
            emotionalTone = "dreamlike, ethereal, mystical, subconscious"
        }
        
        // Görüntü stili ve ruh hali belirle
        let imageStyle = "cinematic, detailed, dramatic lighting, hyperrealistic dream state"
        
        // Gelişmiş sanatsal prompt oluştur
        return """
        A photorealistic dream scene with the following elements prominently featured: \(keywordEmphasis). 
        The dream shows: \(content). 
        Emotional tone: \(emotionalTone). 
        Style: \(imageStyle). 
        Amazing dream visualization, ultra detailed, 8k resolution.
        """
    }
}
