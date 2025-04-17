import Foundation
import SwiftUI

class StatisticsViewModel: ObservableObject {
    @Published var statistics: DreamStatistics = DreamStatistics()
    @Published var isLoading: Bool = false
    @Published var timeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "Hafta"
        case month = "Ay"
        case threeMonths = "3 Ay"
        case sixMonths = "6 Ay"
        case year = "Yıl"
        case allTime = "Tüm Zamanlar"
        
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .allTime: return Int.max
            }
        }
    }
    
    private let coreDataManager = CoreDataManager.shared
    
    func loadStatistics() {
        isLoading = true
        
        let dreams = coreDataManager.fetchAllDreams()
        
        // Tarih filtrelemesi
        let filteredDreams: [Dream]
        if timeRange == .allTime {
            filteredDreams = dreams
        } else {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
            filteredDreams = dreams.filter { $0.date > cutoffDate }
        }
        
        // Toplam rüya sayısı
        statistics.totalDreams = filteredDreams.count
        
        // Duygu dağılımı
        var moodCounts: [Dream.DreamMood: Int] = [:]
        for mood in Dream.DreamMood.allCases {
            moodCounts[mood] = 0
        }
        
        for dream in filteredDreams {
            moodCounts[dream.mood, default: 0] += 1
        }
        statistics.moodDistribution = moodCounts
        
        // En yaygın temalar
        var themeCounts: [String: Int] = [:]
        for dream in filteredDreams {
            if let analysis = dream.analysis {
                for theme in analysis.themes {
                    themeCounts[theme, default: 0] += 1
                }
            }
        }
        
        let sortedThemes = themeCounts.sorted { $0.value > $1.value }
        statistics.mostCommonThemes = sortedThemes.prefix(5).map { ($0.key, $0.value) }
        
        // Zaman içinde rüyalar
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        var dateCounts: [Date: Int] = [:]
        for dream in filteredDreams {
            let date = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: dream.date)) ?? dream.date
            dateCounts[date, default: 0] += 1
        }
        
        statistics.dreamsOverTime = dateCounts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        
        // Haftalık ortalama
        if !filteredDreams.isEmpty {
            let oldestDreamDate = filteredDreams.map { $0.date }.min() ?? Date()
            let daysSinceFirstDream = Calendar.current.dateComponents([.day], from: oldestDreamDate, to: Date()).day ?? 1
            let weeksSinceFirstDream = max(1, Double(daysSinceFirstDream) / 7.0)
            statistics.averageDreamsPerWeek = Double(filteredDreams.count) / weeksSinceFirstDream
        } else {
            statistics.averageDreamsPerWeek = 0
        }
        
        // En sık tekrarlanan öğeler
        var elementCounts: [String: Int] = [:]
        for dream in filteredDreams {
            if let analysis = dream.analysis {
                for element in analysis.recurringElements {
                    elementCounts[element, default: 0] += 1
                }
            }
        }
        
        let sortedElements = elementCounts.sorted { $0.value > $1.value }
        statistics.mostRecurringElements = sortedElements.prefix(5).map { ($0.key, $0.value) }
        
        isLoading = false
    }
}
