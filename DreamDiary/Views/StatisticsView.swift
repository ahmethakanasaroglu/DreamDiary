import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddDreamView = false // Yeni rüya ekle sayfasını göstermek için state ekledim
    @EnvironmentObject private var dreamListViewModel: DreamListViewModel

    
    // Tema renklerini tanımlama
    private var primaryColor: Color {
        colorScheme == .dark ? Color.indigo : Color.indigo
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.purple : Color.purple
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? Color.teal : Color.teal
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.3)
    }
    
    // Tarih formatları
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.statistics.totalDreams == 0 {
                        emptyStateView
                    } else {
                        statisticsContent
                    }
                    
                    // Boşluk ekleyerek ekranın altında yeterli alan olmasını sağlama
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
            }
            .navigationTitle("İstatistikler")
            .background(
                colorScheme == .dark ?
                    Color.black.opacity(0.8) :
                    Color.gray.opacity(0.05)
            )
            .onAppear {
                viewModel.loadStatistics()
            }
            // Yeni rüya ekle sayfasına navigasyon
            .navigationDestination(isPresented: $showingAddDreamView) {
                AddDreamView(viewModel: dreamListViewModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Başlık ve Açıklama
            VStack(alignment: .leading, spacing: 6) {
                Text("Rüya Analitiği")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
                
                Text("Rüya günlüğünün detaylı analizlerine göz at")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
            
            // Gelişmiş zaman aralığı seçici
            VStack(alignment: .leading, spacing: 8) {
                Text("Zaman Aralığı")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                timeRangePicker
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatisticsViewModel.TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        withAnimation {
                            viewModel.timeRange = range
                        }
                    }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.timeRange == range ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.timeRange == range ?
                                          primaryColor :
                                          Color.gray.opacity(0.15))
                            )
                            .foregroundColor(viewModel.timeRange == range ? .white : .primary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(primaryColor)
            
            Text("İstatistikler yükleniyor...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie")
                .font(.system(size: 70))
                .foregroundColor(primaryColor.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("Henüz yeterli veri yok")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("İstatistiklerini görmek için daha fazla rüya kaydet ve analiz et.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                // Yeni rüya ekleme ekranına yönlendirme
                showingAddDreamView = true
            }) {
                Label("Yeni Rüya Ekle", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .padding(.vertical, 40)
    }
    
    // MARK: - Main Statistics Content
    private var statisticsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Genel istatistik kartları
            overviewSection
            
            // Duygu dağılımı grafiği
            moodDistributionSection
            
            // Zaman içindeki rüyalar grafiği
            dreamsOverTimeSection
            
            // En yaygın temalar
            themesSection
            
            // En sık tekrarlanan öğeler
            if !viewModel.statistics.mostRecurringElements.isEmpty {
                recurringElementsSection
            }
            
            // İnsight kartları
            insightsSection
        }
    }
    
    // MARK: - Section Builder
    private func sectionWithTitle<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section başlığı
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(primaryColor)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 2)
            
            // Section içeriği
            content()
                .transition(.opacity)
        }
    }
    
    // MARK: - Dashboard Cards
    private var overviewSection: some View {
        sectionWithTitle("Genel Bakış", icon: "chart.bar.doc.horizontal") {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                dashboardCard(
                    title: "Toplam Rüya",
                    value: "\(viewModel.statistics.totalDreams)",
                    icon: "moon.stars.fill",
                    color: primaryColor
                )
                
                dashboardCard(
                    title: "Haftalık Ortalama",
                    value: String(format: "%.1f", viewModel.statistics.averageDreamsPerWeek),
                    icon: "calendar",
                    color: secondaryColor
                )
                
                // Daha fazla kart eklenebilir
                dashboardCard(
                    title: "Ortalama Uyku",
                    value: "7.2 saat",
                    icon: "bed.double.fill",
                    color: accentColor
                )
                
                dashboardCard(
                    title: "Lucid Rüyalar",
                    value: "\(viewModel.statistics.totalDreams / 5)", // Örnek değer
                    icon: "sparkles",
                    color: Color.orange
                )
            }
        }
    }
    
    private func dashboardCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Üst kısım - İkon ve Başlık
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .padding(10)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Circle())
                
                Spacer()
                
                // Trend göstergesi (isteğe bağlı)
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Alt kısım - İstatistik değeri ve başlık
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Mood Distribution Chart
    private var moodDistributionSection: some View {
        sectionWithTitle("Duygu Dağılımı", icon: "heart.fill") {
            VStack(alignment: .leading, spacing: 16) {
                // Chart Container
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackgroundColor)
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 20) {
                        Chart {
                            ForEach(Array(viewModel.statistics.moodDistribution.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { mood in
                                if let count = viewModel.statistics.moodDistribution[mood], count > 0 {
                                    SectorMark(
                                        angle: .value("Sayı", count),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .cornerRadius(4)
                                    .foregroundStyle(by: .value("Duygu", mood.rawValue))
                                    .annotation(position: .overlay) {
                                        Text("\(count)")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .frame(height: 240)
                        .padding(.top, 8)
                        
                        // Gösterge
                        moodLegend
                    }
                    .padding(16)
                }
                
                // İçgörü kartı
                insightCard(
                    text: "En çok hissettiğin duygu: \(dominantMood)",
                    color: dominantMoodColor
                )
            }
        }
    }
    
    // En yüksek duygu ve rengi (örnek amaçlı)
    private var dominantMood: String {
        if let maxMood = viewModel.statistics.moodDistribution.max(by: { $0.value < $1.value }) {
            return maxMood.key.rawValue
        }
        return "Belirsiz"
    }
    
    private var dominantMoodColor: Color {
        switch dominantMood {
            case "Mutlu": return .green
            case "Üzgün": return .blue
            case "Korkmuş": return .red
            case "Şaşkın": return .orange
            case "Sakin": return .teal
            default: return primaryColor
        }
    }
    
    private var moodLegend: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(Array(viewModel.statistics.moodDistribution.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { mood in
                if let count = viewModel.statistics.moodDistribution[mood], count > 0 {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(moodColor(for: mood))
                            .frame(width: 12, height: 12)
                        
                        Text(mood.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func moodColor(for mood: Dictionary<Dream.DreamMood, Int>.Keys.Element) -> Color {
        switch mood.rawValue {
            case "Mutlu": return .green
            case "Üzgün": return .blue
            case "Korkmuş": return .red
            case "Şaşkın": return .orange
            case "Sakin": return .teal
            default: return .purple
        }
    }
    
    // MARK: - Dreams Over Time Chart
    private var dreamsOverTimeSection: some View {
        sectionWithTitle("Zaman İçinde Rüyalar", icon: "chart.xyaxis.line") {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBackgroundColor)
                        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Günlük rüya kaydı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Chart {
                            ForEach(viewModel.statistics.dreamsOverTime, id: \.date) { item in
                                BarMark(
                                    x: .value("Tarih", item.date, unit: .day),
                                    y: .value("Sayı", item.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(6)
                            }
                            
                            // Ortalama çizgisi (isteğe bağlı)
                            RuleMark(
                                y: .value("Ortalama", viewModel.statistics.averageDreamsPerWeek / 7)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                            .foregroundStyle(Color.red)
                            .annotation(position: .trailing) {
                                Text("Ort.")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(height: 240)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel()
                            }
                        }
                    }
                    .padding(16)
                }
                
                // İçgörü kartı
                insightCard(
                    text: "Son 7 günde \(lastWeekDreamsCount) rüya kaydettin. Bu, ortalamaya göre \(lastWeekComparisonText).",
                    color: lastWeekComparisonColor
                )
            }
        }
    }
    
    // Geçen hafta karşılaştırma verisi (örnek amaçlı)
    private var lastWeekDreamsCount: Int {
        viewModel.statistics.dreamsOverTime.suffix(7).reduce(0) { $0 + $1.count }
    }
    
    private var lastWeekComparisonText: String {
        let avg = viewModel.statistics.averageDreamsPerWeek
        if Double(lastWeekDreamsCount) > avg {
            return "\(Int((Double(lastWeekDreamsCount) / avg - 1) * 100))% daha fazla"
        } else if Double(lastWeekDreamsCount) < avg {
            return "\(Int((1 - Double(lastWeekDreamsCount) / avg) * 100))% daha az"
        } else {
            return "aynı seviyede"
        }
    }
    
    private var lastWeekComparisonColor: Color {
        if Double(lastWeekDreamsCount) > viewModel.statistics.averageDreamsPerWeek {
            return .green
        } else if Double(lastWeekDreamsCount) < viewModel.statistics.averageDreamsPerWeek {
            return .orange
        } else {
            return .gray
        }
    }
    
    // MARK: - Themes Chart
    private var themesSection: some View {
        sectionWithTitle("En Yaygın Temalar", icon: "tag.fill") {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Chart {
                        ForEach(viewModel.statistics.mostCommonThemes, id: \.theme) { item in
                            BarMark(
                                x: .value("Sayı", item.count),
                                y: .value("Tema", item.theme)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.7), accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(6)
                            .annotation(position: .trailing) {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 30 * CGFloat(min(5, viewModel.statistics.mostCommonThemes.count)))
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis(.hidden)
                    
                    // Daha fazla tema göster/gizle butonu
                    if viewModel.statistics.mostCommonThemes.count > 5 {
                        Button(action: {
                            // Tüm temaları göster/gizle
                        }) {
                            Text("Tüm temaları göster")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(accentColor)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Recurring Elements
    private var recurringElementsSection: some View {
        sectionWithTitle("En Sık Tekrarlanan Öğeler", icon: "repeat") {
            VStack(spacing: 12) {
                ForEach(viewModel.statistics.mostRecurringElements, id: \.element) { item in
                    HStack(spacing: 16) {
                        // Emoji veya ikon
                        ZStack {
                            Circle()
                                .fill(primaryColor.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            Text("🔍")
                                .font(.title3)
                        }
                        
                        // Element ve sayı
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.element)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(item.count) rüyada")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // İlerleme çubuğu
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(primaryColor)
                                .frame(width: 60 * CGFloat(item.count) / CGFloat(maxRecurringCount), height: 8)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(16)
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
                }
            }
        }
    }
    
    private var maxRecurringCount: Int {
        viewModel.statistics.mostRecurringElements.first?.count ?? 1
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        sectionWithTitle("Öne Çıkan İçgörüler", icon: "lightbulb.fill") {
            VStack(spacing: 16) {
                insightCard(
                    text: "En çok rüya kaydettiğin tarih: \(formattedMostActiveDate)",
                    color: .blue
                )
                
                insightCard(
                    text: "Senin için en verimli uyku süresi: 7-8 saat",
                    color: .green
                )
                
                insightCard(
                    text: "Stresli günlerin ardından kabus görme olasılığın artıyor",
                    color: .orange
                )
            }
        }
    }
    
    // Formatlanmış en aktif tarih
    private var formattedMostActiveDate: String {
        if let date = viewModel.statistics.mostActiveDreamDate {
            return dateFormatter.string(from: date)
        } else {
            return "Belirsiz"
        }
    }
    
    private func insightCard(text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 4)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Preview
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}

// Varsayılan enum ve modeller (Orijinalinizdeki sınıfları buraya ekleyebilirsiniz)
enum DreamMood: String, CaseIterable {
    case happy = "Mutlu"
    case sad = "Üzgün"
    case scared = "Korkmuş"
    case surprised = "Şaşkın"
    case calm = "Sakin"
}

// MARK: - Model güncelleme için DreamStatistics eklentisi
extension DreamStatistics {
    // En aktif rüya tarihi
    var mostActiveDreamDate: Date? {
        // dreamsOverTime içinden en yüksek count değerine sahip tarihi bul
        let maxDateCount = dreamsOverTime.max { $0.count < $1.count }
        return maxDateCount?.date
    }
}
