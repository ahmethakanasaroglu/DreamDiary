import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var isDarkModeEnabled: Bool {
        didSet {
            if isDarkModeEnabled != oldValue {
                applyTheme()
            }
        }
    }
    @Published var notificationsEnabled: Bool
    @Published var notificationTime: Date
    
    // Bilinçli rüya ayarları
    @Published var lucidDreamingEnabled: Bool
    @Published var selectedLucidTechnique: LucidDreamingTechnique
    @Published var lucidDreamReminderTime: Date
    @Published var showLucidDreamTips: Bool
    
    private let settingsManager = SettingsManager.shared
    
    init() {
        let settings = settingsManager.settings
        self.isDarkModeEnabled = settings.isDarkModeEnabled
        self.notificationsEnabled = settings.notificationsEnabled
        self.notificationTime = settings.notificationTime
        
        // Bilinçli rüya ayarlarını yükle
        self.lucidDreamingEnabled = settings.lucidDreamingEnabled
        self.selectedLucidTechnique = settings.selectedLucidTechnique
        self.lucidDreamReminderTime = settings.lucidDreamReminderTime
        self.showLucidDreamTips = settings.showLucidDreamTips
        
        // Uygulama başlangıcında temayı uygula
        applyTheme()
    }
    
    func saveSettings() {
        var settings = settingsManager.settings
        settings.isDarkModeEnabled = isDarkModeEnabled
        settings.notificationsEnabled = notificationsEnabled
        settings.notificationTime = notificationTime
        
        // Bilinçli rüya ayarlarını kaydet
        settings.lucidDreamingEnabled = lucidDreamingEnabled
        settings.selectedLucidTechnique = selectedLucidTechnique
        settings.lucidDreamReminderTime = lucidDreamReminderTime
        settings.showLucidDreamTips = showLucidDreamTips
        
        settingsManager.settings = settings
    }
    
    func updateNotifications() {
        if notificationsEnabled || lucidDreamingEnabled {
            settingsManager.requestNotificationPermission()
            settingsManager.scheduleNotification()
        } else {
            // Bildirimleri devre dışı bırak
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    // Tema değişikliğini uygulama genelinde aktif hale getiren metod
    private func applyTheme() {
        // iOS 13 ve üzeri için sistem genelinde tema değişikliği
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = isDarkModeEnabled ? .dark : .light
        }
        
        // SwiftUI için uygun görünümü ayarlama (isteğe bağlı)
        NotificationCenter.default.post(name: Notification.Name("ThemeChanged"), object: nil)
    }
    
    // Seçilen tekniğe ait açıklama metni
    var currentTechniqueDescription: String {
        return selectedLucidTechnique.description
    }
    
    // Seçilen tekniğe ait ipuçları
    var currentTechniqueTips: [String] {
        return selectedLucidTechnique.tips
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Başlık
                Text("Rüya Günlüğü Uygulaması Gizlilik Politikası")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Giriş
                sectionTitle("Giriş")
                
                Text("Rüya Günlüğü uygulamasını kullandığınız için teşekkür ederiz. Gizliliğinizi korumak bizim için önemlidir. Bu gizlilik politikası, uygulamayı kullanırken hangi bilgilerin toplandığını, nasıl kullanıldığını ve korunduğunu açıklamaktadır.")
                    .padding(.bottom, 5)
                
                // Toplanan bilgiler
                sectionTitle("Toplanan Bilgiler")
                
                subSectionTitle("Kullanıcı Tarafından Sağlanan Veriler")
                
                bulletPoint("Rüya açıklamaları ve içerikleri")
                bulletPoint("Rüya başlıkları")
                bulletPoint("Kullanıcı tarafından oluşturulan etiketler")
                bulletPoint("Uygulama ayarları ve tercihler")
                
                subSectionTitle("Otomatik Olarak Toplanan Veriler")
                
                bulletPoint("Uygulama kullanım istatistikleri")
                bulletPoint("Hata raporları")
                bulletPoint("Cihaz bilgileri (işletim sistemi versiyonu, model)")
                
                // Verilerin kullanımı
                sectionTitle("Verilerin Kullanımı")
                
                Text("Topladığımız bilgileri şu amaçlarla kullanıyoruz:")
                    .padding(.bottom, 5)
                
                bulletPoint("Rüya analizi hizmetini sağlamak")
                bulletPoint("Rüya görselleştirme özelliğini sunmak")
                bulletPoint("Uygulamanın performansını ve işlevselliğini iyileştirmek")
                bulletPoint("Teknik sorunları tespit etmek ve gidermek")
                
                // Veri paylaşımı
                sectionTitle("Veri Paylaşımı")
                
                subSectionTitle("Üçüncü Taraf Servisler")
                
                Text("Uygulamamız, rüya analizi ve görsel oluşturma gibi gelişmiş özellikler sunmak için aşağıdaki üçüncü taraf servisleri kullanabilir:")
                    .padding(.bottom, 5)
                
                Group {
                    Text("**Yapay Zeka Servisleri**: Rüya analizleri için OpenAI API veya yerel Ollama servisleri")
                    Text("**Görsel Oluşturma Servisleri**: Hugging Face API veya yerel Stable Diffusion servisleri")
                }.padding(.leading)
                
                Text("Bu servislerle paylaşılan veriler, ilgili servislerin kendi gizlilik politikalarına tabidir.")
                    .padding(.top, 5)
                
                subSectionTitle("Diğer Paylaşımlar")
                
                Text("Kişisel verilerinizi şu durumlar dışında üçüncü taraflarla paylaşmıyoruz:")
                    .padding(.bottom, 5)
                
                bulletPoint("Yasal bir zorunluluk olduğunda")
                bulletPoint("Kullanıcı güvenliğini sağlamak için gerekli olduğunda")
                bulletPoint("Açık rızanız olduğunda")
                
                // Veri güvenliği
                sectionTitle("Veri Güvenliği")
                
                Text("Verilerinizin güvenliğini sağlamak için şu önlemleri alıyoruz:")
                    .padding(.bottom, 5)
                
                bulletPoint("Tüm veriler cihazınızda yerel olarak saklanır")
                bulletPoint("Uygulamadan başka uygulamalara veri aktarımı kullanıcı onayına tabidir")
                bulletPoint("Uygulamaya özel şifreleme kullanılmaktadır")
                
                // Veri saklama ve silme
                sectionTitle("Veri Saklama ve Silme")
                
                bulletPoint("Verileriniz, uygulamayı kullandığınız sürece saklanır")
                bulletPoint("Uygulamayı sildiğinizde, yerel verileriniz cihazınızdan silinir")
                bulletPoint("Uygulama içinden de verilerinizi istediğiniz zaman silebilirsiniz")
                
                // Çocukların gizliliği
                sectionTitle("Çocukların Gizliliği")
                
                Text("Uygulamamız 13 yaşın altındaki çocuklar için tasarlanmamıştır. Bilerek 13 yaşın altındaki çocuklardan kişisel bilgi toplamıyoruz.")
                
                // Politika değişiklikleri
                sectionTitle("Politika Değişiklikleri")
                
                Text("Gizlilik politikamızda yapılacak değişiklikler bu sayfada yayınlanacaktır. Düzenli olarak kontrol etmenizi öneririz.")
                
                // İletişim
                sectionTitle("İletişim")
                
                Text("Gizlilik politikamız veya verilerinizin kullanımı hakkında sorularınız varsa, lütfen şu adrese e-posta gönderin:")
                    .padding(.bottom, 5)
                
                Text("dream-journal@example.com")
                    .fontWeight(.bold)
                
                // Son güncelleme
                sectionTitle("Son Güncelleme")
                
                Text("Bu gizlilik politikası son olarak 16 Nisan 2025 tarihinde güncellenmiştir.")
                
                Divider()
                    .padding(.vertical)
                
                Text("Rüya Günlüğü uygulamasını kullanarak, bu gizlilik politikasının şartlarını kabul etmiş olursunuz.")
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Gizlilik Politikası")
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 10)
            .padding(.bottom, 5)
    }
    
    private func subSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.top, 5)
            .padding(.bottom, 2)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
                .padding(.trailing, 5)
            Text(text)
            Spacer()
        }
        .padding(.leading, 10)
        .padding(.bottom, 2)
    }
}
