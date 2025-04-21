import SwiftUI

@main
struct DreamDiaryApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var dreamListViewModel = DreamListViewModel()
    
    // Network kontrolü için gerekli state nesneleri
    @StateObject private var networkManager = NetworkManager.shared
    @State private var showNetworkAlert = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppFlowManager()
                    .environmentObject(dreamListViewModel)
                    .environmentObject(themeManager)
                    .onAppear {
                        // Uygulama açıldığında internet kontrolü yap
                        if !networkManager.isConnected {
                            showNetworkAlert = true
                        }
                    }
                
                // İnternet bağlantısı olmadığında gösterilecek alert
                if showNetworkAlert {
                    NetworkAlertView(isPresented: $showNetworkAlert) {
                        // Tamam'a basıldığında uygulamayı kapat
                        exit(0)
                    }
                }
            }
            // Bağlantı durumu değiştiğinde (kesildiğinde) alert göster
            .onChange(of: networkManager.isConnected) { isConnected in
                if !isConnected {
                    showNetworkAlert = true
                }
            }
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
