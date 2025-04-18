import Foundation

struct Settings: Codable {
    var isDarkModeEnabled: Bool = false
    var notificationsEnabled: Bool = true
    var notificationTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
}
