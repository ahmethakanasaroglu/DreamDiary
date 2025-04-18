import Foundation

struct Settings: Codable {
    var isDarkModeEnabled: Bool = false
    var notificationsEnabled: Bool = true
    var notificationTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Bilinçli Rüya (Lucid Dreaming) ayarları
    var lucidDreamingEnabled: Bool = false
    var selectedLucidTechnique: LucidDreamingTechnique = .reality
    var lucidDreamReminderTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    var showLucidDreamTips: Bool = true
}

// Bilinçli rüya görme teknikleri
enum LucidDreamingTechnique: String, Codable, CaseIterable {
    case reality = "Gerçeklik Kontrolü"
    case mild = "MILD Tekniği"
    case wild = "WILD Tekniği"
    case wbtb = "WBTB Tekniği"
    case astral = "Astral Seyahat"
    
    var description: String {
        switch self {
        case .reality:
            return "Gün içinde düzenli olarak gerçeklik kontrolü yaparak rüyada olup olmadığınızı test etmenizi sağlar."
        case .mild:
            return "Uyumadan önce bilinçli rüya görme niyetinizi güçlendiren ve hatırlamanızı sağlayan teknik."
        case .wild:
            return "Uyanıklıktan doğrudan rüya durumuna geçmenizi sağlayan ileri seviye bir teknik."
        case .wbtb:
            return "Uyku sırasında kalkıp kısa bir süre uyanık kaldıktan sonra tekrar uyuyarak bilinç farkındalığını artıran teknik."
        case .astral:
            return "Bilinçli rüya ve astral seyahat arasında bağlantı kuran meditasyon ve konsantrasyon teknikleri."
        }
    }
    
    var tips: [String] {
        switch self {
        case .reality:
            return [
                "Ellerinize bakın ve parmaklarınızı sayın - rüyada genellikle farklı görünürler",
                "Saate bakın, gözlerinizi kapatın ve tekrar bakın - rüyada zaman farklı akar",
                "Burnunuzu kapatıp nefes almayı deneyin - rüyada nefes alabilirsiniz",
                "Bir yazıya bakın, başka yöne bakın ve tekrar okuyun - rüyada yazılar değişir"
            ]
        case .mild:
            return [
                "Uyumadan önce 'Rüyamda bilinçli olacağım' diye tekrarlayın",
                "Önceki rüyalarınızı hatırlayıp, onları bilinçli olarak tekrar yaşamayı hayal edin",
                "Bilinçli rüya göreceğinize dair güçlü bir niyet oluşturun",
                "Son düşünceniz rüyanızda bilinçli olmak olsun"
            ]
        case .wild:
            return [
                "Vücudunuz uyurken zihninizi uyanık tutmaya odaklanın",
                "Hipnagojik görüntülere dikkat edin ve onları bilinçli olarak yönlendirin",
                "Vücudunuzun uyuşmasını hissettiğinizde paniğe kapılmayın",
                "Kendinizi rüya sahnesine geçiş yaparken hayal edin"
            ]
        case .wbtb:
            return [
                "5-6 saat uyuduktan sonra 20-30 dakika uyanık kalın",
                "Uyanık kaldığınız sürede bilinçli rüya hakkında okuyun",
                "Tekrar uyumadan önce bilinçli rüya göreceğinize dair niyet oluşturun",
                "REM uykusuna girerken zihninizin uyanık kalmasına odaklanın"
            ]
        case .astral:
            return [
                "Uyumadan önce derin meditasyon yapın",
                "Vücudunuzun dışına çıktığınızı ve yüzdüğünüzü hayal edin",
                "Titreşim hissini fark edin ve korkuya kapılmayın",
                "İp merdiven veya spiral yol gibi çıkış sembollerini hayal edin"
            ]
        }
    }
}
