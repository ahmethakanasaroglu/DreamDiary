import SwiftUI

struct AppFlowManager: View {
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @State private var showSplash: Bool = true
    @EnvironmentObject var dreamListViewModel: DreamListViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Splash ekranını her zaman gösteriyoruz
            if showSplash {
                SplashScreen(showMainContent: $showSplash)
            }
            // Splash bittikten sonra, ilk kurulumsa onboarding'i göster
            else if isFirstLaunch {
                OnboardingView(isFirstLaunch: $isFirstLaunch)
            }
            // İlk kurulum değilse veya onboarding bittiyse ana içeriğe git
            else {
                ContentView()
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            }
        }
    }
}

struct AppFlowManager_Previews: PreviewProvider {
    static var previews: some View {
        AppFlowManager()
            .environmentObject(DreamListViewModel())
            .environmentObject(ThemeManager())
    }
}
