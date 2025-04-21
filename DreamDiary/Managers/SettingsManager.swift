import Foundation
import UserNotifications

class SettingsManager {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "dreamDiarySettings"
    
    // Bildirim tanımlayıcıları
    private let dreamReminderIdentifier = "dreamReminder"
    private let lucidDreamReminderIdentifier = "lucidDreamReminder"
    
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
        // Mevcut tüm bildirimleri temizleme
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Rüya günlüğü hatırlatıcısı
        if settings.notificationsEnabled {
            scheduleReminder(
                identifier: dreamReminderIdentifier,
                title: "Rüya Günlüğü",
                body: "Dün gece bir rüya gördün mü? Hemen kaydet!",
                time: settings.notificationTime,
                repeats: true
            )
        }
        
        // Bilinçli rüya hatırlatıcısı
        if settings.lucidDreamingEnabled {
            // Seçilen tekniğe göre bildirim içeriğini belirle
            let technique = settings.selectedLucidTechnique
            let tipIndex = Int.random(in: 0..<technique.tips.count)
            let tip = technique.tips[tipIndex]
            
            scheduleReminder(
                identifier: lucidDreamReminderIdentifier,
                title: "Bilinçli Rüya Hatırlatıcısı",
                body: "\(technique.rawValue) için ipucu: \(tip)",
                time: settings.lucidDreamReminderTime,
                repeats: true
            )
        }
    }
    
    // Genel bildirim oluşturma metodu
    private func scheduleReminder(identifier: String, title: String, body: String, time: Date, repeats: Bool) {
        // Bildirim içeriği oluştur
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Bildirimin gönderileceği zamanı ayarla
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        
        // Bildirimi oluştur
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi planla
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim planlanamadı: \(error.localizedDescription)")
            }
        }
    }
}
