import Foundation
import UserNotifications

class SettingsManager {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "dreamDiarySettings"
    
    var settings: Settings {
        get {
            if let data = userDefaults.data(forKey: settingsKey) {
                let decoder = JSONDecoder()
                if let settings = try? decoder.decode(Settings.self, from: data) {
                    return settings
                }
            }
            return Settings()
        }
        set {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(newValue) {
                userDefaults.set(data, forKey: settingsKey)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Bildirim izni alındı")
            } else if let error = error {
                print("Bildirim izni alınamadı: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification() {
        if settings.notificationsEnabled {
            // Mevcut bildirimleri temizle
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Yeni bildirimi planla
            let content = UNMutableNotificationContent()
            content.title = "Rüya Günlüğü"
            content.body = "Dün gece bir rüya gördün mü? Hemen kaydet!"
            content.sound = .default
            
            // Bildirimin gönderileceği zamanı ayarla
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: settings.notificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Bildirimi oluştur
            let request = UNNotificationRequest(identifier: "dreamReminder", content: content, trigger: trigger)
            
            // Bildirimi planla
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Bildirim planlanamadı: \(error.localizedDescription)")
                }
            }
        }
    }
}
