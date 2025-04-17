import SwiftUI

struct DreamDetailView: View {
    @StateObject private var viewModel: DreamDetailViewModel
    @State private var selectedTab = 0
    
    init(dream: Dream) {
        _viewModel = StateObject(wrappedValue: DreamDetailViewModel(dream: dream))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Rüya başlığı ve duygu durumu
                HStack {
                    Text(viewModel.dream.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(viewModel.dream.mood.emoji)
                        .font(.system(size: 30))
                }
                .padding(.bottom, 5)
                
                // Tarih
                Text(viewModel.dream.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Etiketler
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.dream.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Tab seçici
                Picker("Bölüm", selection: $selectedTab) {
                    Text("İçerik").tag(0)
                    Text("Analiz").tag(1)
                    Text("Görsel").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.vertical)
                
                // Tab içeriği
                Group {
                    if selectedTab == 0 {
                        // Rüya içeriği
                        contentView
                    } else if selectedTab == 1 {
                        // Rüya analizi
                        analysisView
                    } else {
                        // Rüya görseli
                        imageView
                    }
                }
                
                // Hata mesajı
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // İçerik görünümü
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Rüya")
                .font(.headline)
            
            Text(viewModel.dream.content)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    // Analiz görünümü
    private var analysisView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let analysis = viewModel.dream.analysis {
                // Analiz varsa göster
                Group {
                    analysisSection(title: "Temalar", items: analysis.themes)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Yorumlama")
                            .font(.headline)
                        
                        Text(analysis.interpretation)
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Duygusal Ton")
                            .font(.headline)
                        
                        Text(analysis.emotionalTone)
                            .font(.body)
                    }
                    
                    analysisSection(title: "Tekrarlayan Öğeler", items: analysis.recurringElements)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Psikolojik Perspektif")
                            .font(.headline)
                        
                        Text(analysis.psychologicalPerspective)
                            .font(.body)
                    }
                }
            } else {
                // Analiz yoksa analiz butonu göster
                VStack(spacing: 20) {
                    Text("Bu rüya henüz analiz edilmemiş.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        HapticManager.shared.playImpact(style: .medium)
                            Task {
                                await viewModel.analyzeDream()
                            }
                    } label: {
                        HStack {
                            if viewModel.isAnalyzing {
                                ProgressView()
                                    .padding(.trailing, 5)
                            }
                            Text(viewModel.isAnalyzing ? "Analiz Ediliyor..." : "Rüyayı Analiz Et")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isAnalyzing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isAnalyzing)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // Görsel görünümü
    private var imageView: some View {
        VStack(spacing: 20) {
            if let imageURL = viewModel.dream.generatedImageURL,
               let url = URL(string: imageURL),
               let imageData = try? Data(contentsOf: url),
               let uiImage = UIImage(data: imageData) {
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                VStack(spacing: 20) {
                    Text("Bu rüya için henüz bir görsel oluşturulmamış.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        Task {
                            print("Görsel oluşturma butonu tıklandı")
                            await viewModel.generateImage()
                        }
                    } label: {
                        HStack {
                            if viewModel.isGeneratingImage {
                                ProgressView()
                                    .padding(.trailing, 5)
                            }
                            Text(viewModel.isGeneratingImage ? "Görsel Oluşturuluyor..." : "Görsel Oluştur")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isGeneratingImage ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isGeneratingImage)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // Analiz bölümü için yardımcı görünüm
    private func analysisSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            if items.isEmpty {
                Text("Bulunamadı")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(item)
                        }
                    }
                }
            }
        }
    }
}
