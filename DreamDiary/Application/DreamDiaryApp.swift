import SwiftUI

@main
struct DreamDiaryApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var dreamListViewModel = DreamListViewModel()
    
    var body: some Scene {
        WindowGroup {
            AppFlowManager()
                .environmentObject(dreamListViewModel)
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
        DispatchQueue.main.async {
            self.isDarkMode = SettingsManager.shared.settings.isDarkModeEnabled
        }
    }
}
