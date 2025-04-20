import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchResults: [Dream] = []
    @Published var allTags: [String] = []
    @Published var isSearching: Bool = false
    
    private let coreDataManager = CoreDataManager.shared
    private var allDreams: [Dream] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAllDreams()
        
        // DreamListViewModel'den gelen değişiklikleri dinle
        NotificationCenter.default.publisher(for: Notification.Name("DreamDataChanged"))
            .sink { [weak self] _ in
                self?.loadAllDreams()
                self?.loadAllTags()
            }
            .store(in: &cancellables)
    }
    
    func loadAllDreams() {
        allDreams = coreDataManager.fetchAllDreams()
        
        // Aktif bir arama varsa, sonuçları güncelle
        if !searchResults.isEmpty {
            refreshSearchResults()
        }
    }
    
    func loadAllTags() {
        var tagsSet = Set<String>()
        
        for dream in allDreams {
            for tag in dream.tags {
                tagsSet.insert(tag)
            }
        }
        
        allTags = Array(tagsSet).sorted()
    }
    
    func searchDreams(_ query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        
        // Asenkron arama işlemini simüle etmek için küçük bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let lowercasedQuery = query.lowercased()
            
            self.searchResults = self.allDreams.filter { dream in
                // Başlıkta ara
                if dream.title.lowercased().contains(lowercasedQuery) {
                    return true
                }
                
                // İçerikte ara
                if dream.content.lowercased().contains(lowercasedQuery) {
                    return true
                }
                
                // Etiketlerde ara
                if dream.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                    return true
                }
                
                // Analizde ara (varsa)
                if let analysis = dream.analysis {
                    // Temalarda ara
                    if analysis.themes.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                        return true
                    }
                    
                    // Yorumlamada ara
                    if analysis.interpretation.lowercased().contains(lowercasedQuery) {
                        return true
                    }
                    
                    // Tekrarlayan öğelerde ara
                    if analysis.recurringElements.contains(where: { $0.lowercased().contains(lowercasedQuery) }) {
                        return true
                    }
                }
                
                return false
            }
            
            self.isSearching = false
        }
    }
    
    func searchByTag(_ tag: String) {
        isSearching = true
        
        // Asenkron arama işlemini simüle etmek için küçük bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            self.searchResults = self.allDreams.filter { dream in
                dream.tags.contains(tag)
            }
            
            self.isSearching = false
        }
    }
    
    func clearSearch() {
        searchResults = []
        isSearching = false
    }
    
    // Aktif arama sonuçlarını yenile (veri değiştiğinde)
    private func refreshSearchResults() {
        // Etiket araması ile son aranan etiket bilgisini korumamız gerekiyor
        // Bu kullanım örneği için basit bir filtreleme yaptım
        if !searchResults.isEmpty {
            let existingIds = Set(searchResults.map { $0.id })
            
            // Aynı ID'li rüyaları arama sonuçlarında güncelle
            searchResults = allDreams.filter { dream in
                existingIds.contains(dream.id)
            }
        }
    }
}
