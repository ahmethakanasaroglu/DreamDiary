import Foundation
import UIKit

class OpenAIImageService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/images/generations"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateImage(fromPrompt prompt: String) async throws -> String {
        print("OpenAI API görsel oluşturma başlatılıyor")
        
        // Metin Türkçe mi kontrol et
        let isTurkish = detectTurkish(prompt)
        
        // Rüya içeriğinden anahtar kelimeleri çıkar
        let keywords = extractKeywords(from: prompt)
        
        // Metinden duygusal tonu algıla
        let emotionalTone = detectEmotionalTone(from: prompt, isTurkish: isTurkish)
        
        // Rüya temasını algıla
        let dreamTheme = detectDreamTheme(from: prompt, isTurkish: isTurkish)
        
        // Gelişmiş prompt oluştur
        let enhancedPrompt = isTurkish ?
            buildEnhancedPromptForTurkish(content: prompt, keywords: keywords, emotionalTone: emotionalTone, dreamTheme: dreamTheme) :
            buildEnhancedPrompt(content: prompt, keywords: keywords, emotionalTone: emotionalTone, dreamTheme: dreamTheme)
        
        print("Geliştirilmiş prompt: \(enhancedPrompt)")
        
        // JSON formatında istek gövdesi oluştur
        let requestBody: [String: Any] = [
            "model": "dall-e-3", // DALL-E 3 modeli
            "prompt": enhancedPrompt,
            "n": 1, // Bir görsel oluştur
            "size": "1024x1024", // 1024x1024 boyutunda görsel
            "quality": "hd", // Daha yüksek kalite için HD
            "style": "vivid" // Canlı stil (daha gerçekçi)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // İstek gönder ve yanıt bekle
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "HTTP yanıtı alınamadı"])
        }
        
        print("HTTP durum kodu: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Yanıtı ayrıştır
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstImage = dataArray.first,
              let imageUrl = firstImage["url"] as? String else {
            throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        // URL'den görsel verisini al
        let imageData = try await downloadImage(from: imageUrl)
        
        // Görüntüyü dosya sistemine kaydet
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = UUID().uuidString + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        try imageData.write(to: fileURL)
        return fileURL.absoluteString
    }
    
    // URL'den görsel indirme
    private func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAIError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to download image"])
        }
        
        return data
    }
    
    // Geliştirilmiş Türkçe tespit fonksiyonu
    private func detectTurkish(_ text: String) -> Bool {
        // Türkçe karakterler
        let turkishChars = Set(["ı", "ğ", "ü", "ş", "ç", "ö", "İ", "Ğ", "Ü", "Ş", "Ç", "Ö"])
        
        // Yaygın Türkçe kelimeler (genişletilmiş liste)
        let turkishWords = Set([
            "bir", "ve", "ile", "bu", "çok", "için", "ama", "ben", "sen", "biz", "siz",
            "rüya", "gördüm", "kabus", "sonra", "önce", "şimdi", "sanki", "gibi", "aslında",
            "var", "yok", "oldu", "gitti", "geldi", "etti", "içinde", "dışında", "üstünde",
            "altında", "yanında", "karşısında", "arasında", "beraber", "birlikte", "ardından",
            "tarafından", "dolayı", "hakkında", "kadar", "rağmen", "göre", "sanki", "fakat",
            "lakin", "ancak", "oysa", "oysaki", "halbuki", "nasıl", "neden", "niçin", "kim",
            "hangi", "ne", "nerede", "nezaman", "kişi", "insan", "kadın", "erkek", "çocuk"
        ])
        
        let lowercaseText = text.lowercased()
        
        // Türkçe karakter kontrolü
        for char in turkishChars {
            if text.contains(char) {
                return true
            }
        }
        
        // Türkçe kelime kontrolü - geliştirilmiş algılama
        let words = lowercaseText.components(separatedBy: .whitespaces)
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if turkishWords.contains(cleanWord) {
                return true
            }
        }
        
        // Yaygın Türkçe kelime kalıpları kontrolü
        for word in turkishWords {
            if lowercaseText.contains(" \(word) ") ||
               lowercaseText.starts(with: "\(word) ") ||
               lowercaseText.hasSuffix(" \(word)") ||
               lowercaseText == word {
                return true
            }
        }
        
        return false
    }
    
    // Geliştirilmiş anahtar kelime çıkarma fonksiyonu
    private func extractKeywords(from text: String) -> [String] {
        let isTurkish = detectTurkish(text)
        
        // Stopwords - Genişletilmiş liste
        let turkishStopwords = Set([
            "ve", "ile", "bir", "bu", "şu", "o", "da", "de", "ki", "mi", "mı", "mu", "mü",
            "için", "gibi", "kadar", "daha", "çok", "en", "ama", "fakat", "lakin", "ancak",
            "veya", "ya da", "yahut", "ile", "birlikte", "beraber", "sadece", "yalnız", "tek",
            "ise", "değil", "oldu", "oldum", "oldun", "olmuş", "ben", "sen", "o", "biz", "siz",
            "onlar", "beni", "seni", "onu", "bizi", "sizi", "onları", "bana", "sana", "ona",
            "bize", "size", "onlara", "sanki", "acaba", "belki", "evet", "hayır", "tamam",
            "peki", "yani", "işte", "öyle", "böyle", "şöyle", "dolayı", "önce", "sonra",
            "diye", "üzere", "rağmen", "göre", "karşı", "doğru", "herhangi", "hiçbir", "her"
        ])
        
        let englishStopwords = Set([
            "and", "with", "a", "the", "in", "of", "to", "for", "like", "very", "after", "before",
            "was", "were", "i", "me", "my", "myself", "we", "our", "ours", "ourselves",
            "you", "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself",
            "she", "her", "hers", "herself", "it", "its", "itself", "they", "them", "their",
            "theirs", "themselves", "what", "which", "who", "whom", "this", "that", "these",
            "those", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has",
            "had", "having", "do", "does", "did", "doing", "would", "should", "could", "ought",
            "i'm", "you're", "he's", "she's", "it's", "we're", "they're", "i've", "you've",
            "we've", "they've", "i'd", "you'd", "he'd", "she'd", "we'd", "they'd", "i'll",
            "you'll", "he'll", "she'll", "we'll", "they'll", "isn't", "aren't", "wasn't",
            "weren't", "hasn't", "haven't", "hadn't", "doesn't", "don't", "didn't", "won't",
            "wouldn't", "shan't", "shouldn't", "can't", "cannot", "couldn't", "mustn't",
            "let's", "that's", "who's", "what's", "here's", "there's", "when's", "where's",
            "why's", "how's", "because", "since", "while", "until", "whenever", "wherever",
            "whether", "though", "although", "even"
        ])
        
        // Hangi dilde analiz yapılacağını belirle
        let stopwords = isTurkish ? turkishStopwords : englishStopwords
        
        // Punktuasyon ve gereksiz karakterleri temizle
        let cleanedText = text.lowercased()
            .replacingOccurrences(of: "[^a-zğüşıöçİĞÜŞÖÇ0-9\\s]", with: " ", options: .regularExpression)
        
        // Kelimelere ayır
        let words = cleanedText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 && !stopwords.contains($0) }
        
        // Kelime sayımı
        var wordCount: [String: Int] = [:]
        for word in words {
            wordCount[word, default: 0] += 1
        }
        
        // Kelimeleri önem sırasına göre sırala
        let sortedWords = wordCount.sorted { word1, word2 -> Bool in
            // Önce frekansa göre
            if word1.value != word2.value {
                return word1.value > word2.value
            }
            // Sonra kelime uzunluğuna göre (daha uzun kelimeler genelde daha önemli)
            return word1.key.count > word2.key.count
        }
        
        // En önemli 10 kelimeyi seç
        return sortedWords.prefix(10).map { $0.key }
    }
    
    // Duygusal ton algılama
    private func detectEmotionalTone(from text: String, isTurkish: Bool) -> String {
        let lowercaseText = text.lowercased()
        
        // Türkçe duygu kelimeleri
        let turkishEmotions: [String: [String]] = [
            "korku": ["korku", "kabus", "ürkütücü", "dehşet", "korkunç", "korkutucu", "ürpertici", "tedirgin", "endişe", "panik", "terör", "kâbus"],
            "mutluluk": ["mutlu", "sevinç", "güzel", "harika", "muhteşem", "keyif", "neşe", "huzur", "memnun", "sevgi", "aşk", "hoş", "olumlu"],
            "üzüntü": ["üzgün", "keder", "hüzün", "acı", "mutsuz", "gözyaşı", "ağlamak", "yas", "depresif", "melankolik", "çaresiz"],
            "şaşkınlık": ["şaşırtıcı", "tuhaf", "garip", "acayip", "şaşkın", "hayret", "sürpriz", "beklenmedik", "absürt", "alışılmadık"],
            "öfke": ["kızgın", "öfke", "sinir", "kızgınlık", "hiddet", "nefret", "kin", "intikam", "düşmanlık"],
            "özgürlük": ["uçmak", "uçuyorum", "özgür", "özgürlük", "hafiflik", "yüzmek", "süzülmek", "serbest", "kanatlanmak"],
            "iş": ["iş", "şirket", "staj", "çalışma", "toplantı", "profesyonel", "kariyer", "başarı", "ofis", "patron", "mülakat", "terfi"]
        ]
        
        // İngilizce duygu kelimeleri
        let englishEmotions: [String: [String]] = [
            "fear": ["fear", "nightmare", "scary", "terror", "horrific", "frightening", "creepy", "anxious", "worry", "panic", "dread", "terror"],
            "happiness": ["happy", "joy", "beautiful", "amazing", "wonderful", "pleasure", "delight", "peaceful", "content", "love", "positive", "pleasant"],
            "sadness": ["sad", "sorrow", "grief", "pain", "unhappy", "tears", "crying", "mourning", "depressed", "melancholic", "hopeless"],
            "surprise": ["surprising", "strange", "weird", "bizarre", "astonished", "amazement", "surprise", "unexpected", "absurd", "unusual"],
            "anger": ["angry", "anger", "furious", "rage", "hate", "hatred", "vengeance", "hostility"],
            "freedom": ["fly", "flying", "free", "freedom", "lightness", "floating", "soar", "liberated", "wings"],
            "work": ["job", "company", "internship", "working", "meeting", "professional", "career", "success", "office", "boss", "interview", "promotion"]
        ]
        
        // Hangi dilde analiz yapılacağını belirle
        let emotions = isTurkish ? turkishEmotions : englishEmotions
        
        // Her duygu kategorisi için metin içinde kaç eşleşme olduğunu say
        var emotionScores: [String: Int] = [:]
        
        for (category, keywords) in emotions {
            let score = keywords.reduce(0) { count, keyword in
                count + (lowercaseText.contains(keyword) ? 1 : 0)
            }
            emotionScores[category] = score
        }
        
        // En yüksek skorlu duygu kategorisini bul
        if let topEmotion = emotionScores.max(by: { $0.value < $1.value }), topEmotion.value > 0 {
            switch topEmotion.key {
                case "korku", "fear":
                    return "dark, ominous, haunting, mysterious, foreboding, intense, dream-like, symbolic, surreal, eerie, cinematic"
                case "mutluluk", "happiness":
                    return "vibrant, joyful, uplifting, bright, golden, hopeful, inspiring, harmonious, radiant, dreamlike, warm"
                case "üzüntü", "sadness":
                    return "somber, melancholic, bittersweet, contemplative, introspective, wistful, rain-soaked, moody, dreamlike, muted colors"
                case "şaşkınlık", "surprise":
                    return "surreal, bizarre, unexpected, unbelievable, strange, curious, dreamlike, abstract, mind-bending, otherworldly"
                case "öfke", "anger":
                    return "intense, dramatic, powerful, turbulent, fiery, confrontational, chaotic, dream-like, symbolic, red-tones"
                case "özgürlük", "freedom":
                    return "soaring, boundless, expansive, liberating, weightless, ethereal, floating, dreamy, expansive, sky-bound"
                case "iş", "work":
                    return "professional, accomplished, successful, sleek, corporate, formal, achievement, business environment, modern, clean"
                default:
                    return "dreamlike, ethereal, mystical, imaginative, surreal, symbolic, metaphorical, cinematic"
            }
        }
        
        // Varsayılan ton
        return "dreamlike, ethereal, mystical, imaginative, surreal, symbolic, metaphorical, cinematic"
    }
    
    // Rüya temasını tespit et
    private func detectDreamTheme(from text: String, isTurkish: Bool) -> String {
        let lowercaseText = text.lowercased()
        
        // Türkçe tema kelimeleri
        let turkishThemes: [String: [String]] = [
            "iş-başarı": ["iş", "şirket", "işe alın", "staj", "toplantı", "sunum", "terfi", "başarı", "kariyer", "proje", "patron", "çalışma", "ofis", "mülakat", "görüşme"],
            "ilişki": ["aşk", "sevgili", "evlilik", "romantik", "partner", "ilişki", "eş", "flört", "duygusal", "ayrılık", "barışma"],
            "korku": ["kabus", "korku", "dehşet", "ürperti", "karanlık", "canavar", "takip", "kaçış", "saklanma", "panik", "ölüm", "yaralanma"],
            "uçma": ["uçmak", "uçuyorum", "kanat", "gökyüzü", "bulut", "yüksek", "süzülme", "havada", "kuş gibi", "özgürlük", "yükselmek"],
            "düşme": ["düşmek", "düşüyorum", "yüksekten", "boşluk", "uçurum", "derin", "yukarıdan"],
            "arama": ["aramak", "kayıp", "bulamama", "kaybetmek", "bulmaya çalışmak", "çaresiz", "arayış", "peşinde"],
            "sınav": ["sınav", "okul", "hazırlıksız", "test", "başarı", "başarısızlık", "not", "ödev", "geç kalmak", "öğretmen", "okumak"],
            "su": ["su", "deniz", "okyanus", "yüzmek", "boğulmak", "dalga", "sel", "nehir", "göl", "ıslak", "yağmur"],
            "ev": ["ev", "bina", "oda", "çatı", "bahçe", "apartman", "konut", "taşınmak", "eski ev", "yeni ev"]
        ]
        
        // İngilizce tema kelimeleri
        let englishThemes: [String: [String]] = [
            "work-success": ["job", "company", "hired", "internship", "meeting", "presentation", "promotion", "success", "career", "project", "boss", "work", "office", "interview"],
            "relationship": ["love", "romantic", "marriage", "partner", "relationship", "spouse", "dating", "emotional", "breakup", "reconciliation"],
            "fear": ["nightmare", "fear", "terror", "creepy", "dark", "monster", "chase", "escape", "hiding", "panic", "death", "injury"],
            "flying": ["fly", "flying", "wings", "sky", "cloud", "high", "soaring", "air", "bird-like", "freedom", "rising"],
            "falling": ["fall", "falling", "height", "void", "cliff", "deep", "above"],
            "searching": ["search", "lost", "finding", "lose", "trying to find", "desperate", "quest", "pursuing"],
            "test": ["exam", "school", "unprepared", "test", "success", "failure", "grade", "homework", "late", "teacher", "study"],
            "water": ["water", "sea", "ocean", "swim", "drowning", "wave", "flood", "river", "lake", "wet", "rain"],
            "home": ["home", "building", "room", "roof", "garden", "apartment", "residence", "moving", "old house", "new house"]
        ]
        
        // Hangi dilde analiz yapılacağını belirle
        let themes = isTurkish ? turkishThemes : englishThemes
        
        // Her tema kategorisi için metin içinde kaç eşleşme olduğunu say
        var themeScores: [String: Int] = [:]
        
        for (category, keywords) in themes {
            let score = keywords.reduce(0) { count, keyword in
                if lowercaseText.contains(keyword) {
                    return count + 1
                }
                return count
            }
            themeScores[category] = score
        }
        
        // En yüksek skorlu tema kategorisini bul
        if let topTheme = themeScores.max(by: { $0.value < $1.value }), topTheme.value > 0 {
            switch topTheme.key {
                case "iş-başarı", "work-success":
                    return "professional achievement, corporate success, workplace accomplishment, career milestone"
                case "ilişki", "relationship":
                    return "romantic relationship, emotional connection, love story, partnership"
                case "korku", "fear":
                    return "nightmare scenario, fear inducing situation, horror elements, threatening atmosphere"
                case "uçma", "flying":
                    return "flight experience, soaring through skies, aerial freedom, unbound by gravity"
                case "düşme", "falling":
                    return "falling sensation, descent through space, weightlessness, vertigo experience"
                case "arama", "searching":
                    return "search mission, quest for something lost, seeking important object or person, journey"
                case "sınav", "test":
                    return "test preparation, academic pressure, performance anxiety, classroom scenario"
                case "su", "water":
                    return "aquatic environment, underwater scene, ocean depths, flowing water elements"
                case "ev", "home":
                    return "domestic setting, familiar home environment, architectural spaces, rooms and buildings"
                default:
                    return "symbolic dream scenario, subconscious imagery, metaphorical representation"
            }
        }
        
        // Varsayılan tema
        return "symbolic dream scenario, subconscious imagery, metaphorical representation"
    }
    
    // Türkçe içerik için geliştirilmiş görsel prompt oluşturma
    private func buildEnhancedPromptForTurkish(content: String, keywords: [String], emotionalTone: String, dreamTheme: String) -> String {
        // Anahtar kelimeleri İngilizce'ye çevir - Genişletilmiş sözlük
        let turkishToEnglish: [String: String] = [
            // İş ile ilgili
            "iş": "job", "işe": "job", "şirket": "company", "ofis": "office", "çalışma": "work", "çalışmak": "working",
            "toplantı": "meeting", "yönetici": "manager", "patron": "boss", "başarı": "success", "başarılı": "successful",
            "sunum": "presentation", "staj": "internship", "mülakat": "interview", "terfi": "promotion",
            "alınmak": "getting hired", "işe alın": "hiring", "kabul": "acceptance", "teklif": "offer",
            
            // Duygular
            "mutlu": "happy", "sevinç": "joy", "üzgün": "sad", "korku": "fear", "endişe": "anxiety",
            "kabus": "nightmare", "heyecan": "excitement", "şaşkınlık": "surprise", "öfke": "anger",
            "sakin": "calm", "huzur": "peace", "sevgi": "love", "nefret": "hate", "hoşnut": "pleased",
            
            // Zaman ve durum
            "uyanmak": "waking up", "uyandım": "woke up", "zaman": "time", "sonra": "after", "önce": "before",
            "şimdi": "now", "bugün": "today", "dün": "yesterday", "yarın": "tomorrow", 
            "sabah": "morning", "akşam": "evening", "rüya": "dream", "gerçek": "real",
            
            // Niteleyiciler
            "uzun": "long", "kısa": "short", "büyük": "big", "küçük": "small", "hızlı": "fast",
            "yavaş": "slow", "güzel": "beautiful", "çirkin": "ugly", "iyi": "good", "kötü": "bad",
            "zor": "difficult", "kolay": "easy", "güçlü": "strong", "zayıf": "weak",
            
            // Hareket ve yön
            "gitmek": "going", "geldim": "came", "koşmak": "running", "yürümek": "walking", "uçmak": "flying",
            "düşmek": "falling", "yukarı": "up", "aşağı": "down", "içeri": "inside", "dışarı": "outside",
            
            // Diğer yaygın kelimeler
            "insan": "person", "kadın": "woman", "erkek": "man", "çocuk": "child", "aile": "family",
            "arkadaş": "friend", "düşman": "enemy", "ev": "home", "araba": "car", "yol": "road",
            "deniz": "sea", "gökyüzü": "sky", "bulut": "cloud", "yağmur": "rain", "güneş": "sun",
            "ay": "moon", "yıldız": "star", "gece": "night", "gündüz": "day", "su": "water",
            "ateş": "fire", "toprak": "earth", "hava": "air", "doğa": "nature", "hayvan": "animal",
            "bitki": "plant", "ağaç": "tree", "çiçek": "flower", "masa": "table", "sandalye": "chair",
            "bina": "building", "kapı": "door", "pencere": "window", "yemek": "food", "içecek": "drink"
        ]
        
        // Metnin İngilizce özetini çıkar
        var translatedSummary = "a dream about "
        
        // Türkçedeki önemli temayı tespit et ve özetini çıkar
        if content.lowercased().contains("işe") && (content.lowercased().contains("alın") || content.lowercased().contains("kabul")) {
            translatedSummary = "a dream about getting hired at a company"
            
            if content.lowercased().contains("sunum") {
                translatedSummary += " after a successful presentation"
            }
            
            if content.lowercased().contains("staj") {
                translatedSummary += " following an internship"
            }
            
            if content.lowercased().contains("mülakat") || content.lowercased().contains("görüşme") {
                translatedSummary += " after an interview"
            }
            
            if content.lowercased().contains("mutlu") || content.lowercased().contains("sevin") {
                translatedSummary += ", with feelings of joy and accomplishment"
            }
        }
        else if content.lowercased().contains("uç") && (content.lowercased().contains("uçmak") || content.lowercased().contains("uçuyor")) {
            translatedSummary = "a dream about flying freely through the air"
            
            if content.lowercased().contains("bulut") {
                translatedSummary += " above clouds"
            }
            
            if content.lowercased().contains("şehir") || content.lowercased().contains("kent") {
                translatedSummary += " over a city"
            }
            
            if content.lowercased().contains("özgür") || content.lowercased().contains("özgürlük") {
                translatedSummary += " with a sense of freedom"
            }
        }
        else if content.lowercased().contains("düş") && (content.lowercased().contains("düşmek") || content.lowercased().contains("düşüyor")) {
            translatedSummary = "a dream about falling from a height"
            
            if content.lowercased().contains("uyan") {
                translatedSummary += " and then waking up suddenly"
            }
            
            if content.lowercased().contains("korku") || content.lowercased().contains("endişe") {
                translatedSummary += " with feelings of fear and anxiety"
            }
        }
        else if content.lowercased().contains("kabus") || (content.lowercased().contains("korku") && content.lowercased().contains("rüya")) {
            translatedSummary = "a nightmare with frightening elements"
            
            if content.lowercased().contains("takip") || content.lowercased().contains("koval") {
                translatedSummary += " involving being chased"
            }
            
            if content.lowercased().contains("karanlık") {
                translatedSummary += " in darkness"
            }
            
            if content.lowercased().contains("canavar") || content.lowercased().contains("yaratık") {
                translatedSummary += " by a monster or creature"
            }
        }
        else {
            // Genel rüya içeriği - anahtar kelimeleri çevir ve ekle
            let translatedKeywords = keywords.map { turkishToEnglish[$0] ?? $0 }
            translatedSummary += translatedKeywords.joined(separator: ", ")
        }
        
        // Görüntü stili
        let imageStyle = "cinematic quality, professional lighting, vivid colors, highly detailed, 4K, dreamy atmosphere, visual metaphors"
        
        // Gelişmiş prompt - İngilizce
        return """
        Create a photorealistic and evocative visualization of \(translatedSummary).
        
        Primary theme: \(dreamTheme)
        Emotional quality: \(emotionalTone)
        Visual style: \(imageStyle)
        
        The scene should have dreamlike qualities with vivid symbolism and slightly surreal elements that evoke the subconscious mind.
        
        Important visual elements to include:
        - Strong metaphorical representation of the dream's central emotion
        - Dramatic lighting that enhances the mood
        - Rich color palette appropriate to the emotional tone
        - Dream-like atmosphere with subtle distortions of reality
        - Cinematic composition with emphasis on the main subject
        
        The image must NOT contain any text, words, labels, captions, or writing of any kind.
        Create a completely realistic, photographic image, not a cartoon or illustration.
        """
    }
    
    // Standart (İngilizce) için geliştirilmiş görsel prompt oluşturma
    private func buildEnhancedPrompt(content: String, keywords: [String], emotionalTone: String, dreamTheme: String) -> String {
        // Anahtar kelimeleri birleştir
        let keywordEmphasis = keywords.joined(separator: ", ")
        
        // İçeriğin kısa özeti
        var contentSummary = content
        
        // Çok uzun içerikleri kısalt (DALL-E prompt sınırlamaları için)
        if contentSummary.count > 200 {
            contentSummary = String(contentSummary.prefix(200)) + "..."
        }
        
        // Görüntü stili
        let imageStyle = "cinematic quality, professional lighting, vivid colors, highly detailed, 4K, dreamy atmosphere, visual metaphors"
        
        // Gelişmiş prompt
        return """
        Create a photorealistic and evocative visualization of this dream: \(contentSummary)
        
        Primary theme: \(dreamTheme)
        Key elements to emphasize: \(keywordEmphasis)
        Emotional quality: \(emotionalTone)
        Visual style: \(imageStyle)
        
        The scene should have dreamlike qualities with vivid symbolism and slightly surreal elements that evoke the subconscious mind.
        
        Important visual elements to include:
        - Strong metaphorical representation of the dream's central emotion
        - Dramatic lighting that enhances the mood
        - Rich color palette appropriate to the emotional tone
        - Dream-like atmosphere with subtle distortions of reality
        - Cinematic composition with emphasis on the main subject
        
        The image must NOT contain any text, words, labels, captions, or writing of any kind.
        Create a completely realistic, photographic image, not a cartoon or illustration.
        """
    }
}
