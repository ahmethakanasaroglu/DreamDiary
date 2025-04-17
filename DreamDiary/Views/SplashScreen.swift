import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var showMainContent = false
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            if !showMainContent {
                VStack(spacing: 20) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 1 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Text("Rüya Günlüğü")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeIn.delay(0.4), value: isAnimating)
                    
                    Text("Rüyalarınızı kaydedin, analiz edin, keşfedin")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeIn.delay(0.7), value: isAnimating)
                }
                .onAppear {
                    isAnimating = true
                    
                    // 2.5 saniye sonra ana içeriğe geç
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showMainContent = true
                        }
                    }
                }
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
