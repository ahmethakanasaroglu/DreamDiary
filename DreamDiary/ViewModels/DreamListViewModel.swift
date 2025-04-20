import Foundation
import Combine

class DreamListViewModel: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        loadDreams()
    }
    
    func loadDreams() {
        isLoading = true
        dreams = coreDataManager.fetchAllDreams()
        isLoading = false
    }
    
    func addDream(_ dream: Dream) {
        coreDataManager.saveDream(dream)
        loadDreams()
        // Veri değişikliğini bildir
        notifyDataChanged()
    }
    
    func updateDream(_ dream: Dream) {
        coreDataManager.saveDream(dream)
        loadDreams()
        // Veri değişikliğini bildir
        notifyDataChanged()
    }
    
    func deleteDream(at offsets: IndexSet) {
        for index in offsets {
            let dream = dreams[index]
            coreDataManager.deleteDream(id: dream.id)
        }
        loadDreams()
        // Veri değişikliğini bildir
        notifyDataChanged()
    }
    
    // Veri değişikliğini bildirmek için NotificationCenter kullan
    private func notifyDataChanged() {
        NotificationCenter.default.post(name: Notification.Name("DreamDataChanged"), object: nil)
    }
}
