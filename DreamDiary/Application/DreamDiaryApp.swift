import SwiftUI

@main
struct DreamDiaryApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .environmentObject(themeManager)
        }
    }
}

// Uygulama genelinde tema yönetimi için kullanılacak sınıf
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool
    
    init() {
        // Kaydedilmiş tema ayarını al
        self.isDarkMode = SettingsManager.shared.settings.isDarkModeEnabled
        
        // Tema değişikliklerini dinle
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: Notification.Name("ThemeChanged"), object: nil)
    }
    
    @objc private func themeChanged() {
        // Ayarlardan güncel tema durumunu al
        self.isDarkMode = SettingsManager.shared.settings.isDarkModeEnabled
    }
}
