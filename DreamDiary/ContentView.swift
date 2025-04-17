import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DreamListView()
                .tabItem {
                    Label("Rüyalarım", systemImage: "moon.stars")
                }
            
            SearchView()
                .tabItem {
                    Label("Ara", systemImage: "magnifyingglass")
                }
            
            StatisticsView()
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.pie")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
