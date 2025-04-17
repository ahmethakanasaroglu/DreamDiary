import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            image: "book.fill",
            title: "Rüya Günlüğünüz",
            description: "Rüyalarınızı kaydedin, etiketleyin ve zaman içindeki değişimleri izleyin."
        ),
        OnboardingPage(
            image: "wand.and.stars",
            title: "Yapay Zeka Analizi",
            description: "Yapay zeka, rüyalarınızı analiz ederek size içgörüler sunar."
        ),
        OnboardingPage(
            image: "photo.fill",
            title: "Görsel Oluşturma",
            description: "Rüyalarınızı yapay zeka ile görselleştirin ve hatıralarınızı canlandırın."
        ),
        OnboardingPage(
            image: "chart.bar.fill",
            title: "İstatistikler",
            description: "Rüya desenlerinizi keşfedin ve zaman içindeki eğilimleri görün."
        )
    ]
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        isFirstLaunch = false
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Devam" : "Başla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.image)
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isFirstLaunch: .constant(true))
    }
}
