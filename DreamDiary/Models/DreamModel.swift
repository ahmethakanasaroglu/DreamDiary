import Foundation

struct Dream: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var date: Date
    var mood: DreamMood
    var tags: [String] = []
    var imagePrompt: String? = nil
    var generatedImageURL: String? = nil
    var analysis: DreamAnalysis? = nil
    
    enum DreamMood: String, Codable, CaseIterable {
        case positive = "Positive"
        case neutral = "Neutral"
        case negative = "Negative"
        case confusing = "Confusing"
        case scary = "Scary"
        case exciting = "Exciting"
        
        var emoji: String {
            switch self {
            case .positive: return "😊"
            case .neutral: return "😐"
            case .negative: return "😔"
            case .confusing: return "😕"
            case .scary: return "😱"
            case .exciting: return "🤩"
            }
        }
    }
}

struct DreamAnalysis: Codable {
    var themes: [String] = []
    var interpretation: String = ""
    var emotionalTone: String = ""
    var recurringElements: [String] = []
    var psychologicalPerspective: String = ""
}
