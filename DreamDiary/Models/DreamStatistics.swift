import Foundation

struct DreamStatistics {
    var moodDistribution: [Dream.DreamMood: Int] = [:]
    var mostCommonThemes: [(theme: String, count: Int)] = []
    var dreamsOverTime: [(date: Date, count: Int)] = []
    var totalDreams: Int = 0
    var averageDreamsPerWeek: Double = 0
    var mostRecurringElements: [(element: String, count: Int)] = []
}
