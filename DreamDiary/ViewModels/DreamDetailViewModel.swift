import Foundation
import SwiftUI

class DreamDetailViewModel: ObservableObject {
    @Published var dream: Dream
    @Published var isAnalyzing = false
    @Published var isGeneratingImage = false
    @Published var errorMessage: String? = nil
    
    private let ollamaService = OllamaService()
    private let huggingFaceService = HuggingFaceImageService(token: APIKeys.huggingFace) // Görsel oluşturma için
    private let coreDataManager = CoreDataManager.shared
    
    init(dream: Dream) {
        self.dream = dream
    }
    
    func analyzeDream() async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }
        
        do {
            // OpenAI yerine Ollama servisi çağrısı yap
            let analysis = try await ollamaService.analyzeDream(content: dream.content)
            
            await MainActor.run {
                var updatedDream = dream
                updatedDream.analysis = analysis
                self.dream = updatedDream
                
                coreDataManager.saveDream(updatedDream)
                
                isAnalyzing = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Analiz sırasında bir hata oluştu: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }
    
    func generateImage() async {
        await MainActor.run {
            isGeneratingImage = true
            errorMessage = nil
        }
        
        do {
            // Rüya içeriğini başlık ve etiketlerle zenginleştir
            let enhancedPrompt = createEnhancedPrompt(content: dream.content, title: dream.title, tags: dream.tags)
            
            // Hugging Face ile görsel oluştur
            let imageURL = try await huggingFaceService.generateImage(fromPrompt: enhancedPrompt)
            
            await MainActor.run {
                var updatedDream = dream
                updatedDream.imagePrompt = enhancedPrompt
                updatedDream.generatedImageURL = imageURL
                self.dream = updatedDream
                
                coreDataManager.saveDream(updatedDream)
                
                isGeneratingImage = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Görsel oluşturma sırasında bir hata oluştu: \(error.localizedDescription)"
                isGeneratingImage = false
            }
        }
    }
    
    // Rüya içeriğini, başlığı ve etiketleri birleştirerek zenginleştirilmiş bir içerik oluştur
    private func createEnhancedPrompt(content: String, title: String, tags: [String]) -> String {
        var enhancedContent = content
        
        // Başlığı ekle (eğer içerikte yoksa)
        if !content.contains(title) && !title.isEmpty {
            enhancedContent = title + ": " + enhancedContent
        }
        
        // Etiketleri, anahtar kelimeler olarak ekle
        if !tags.isEmpty {
            enhancedContent += "\n\nKey elements: " + tags.joined(separator: ", ")
        }
        
        return enhancedContent
    }
}
