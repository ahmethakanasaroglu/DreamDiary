import Foundation
import Network
import SwiftUI

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = true // Varsayılan olarak true başlatalım
    @Published var initialCheckComplete = false // İlk kontrol tamamlandı mı
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                // İlk kontrol tamamlandığını işaretleyelim
                if !(self?.initialCheckComplete ?? true) {
                    self?.initialCheckComplete = true
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        stopMonitoring()
    }
}

// Minimal ve şık internet bağlantı uyarısı
struct NetworkAlertView: View {
    @Binding var isPresented: Bool
    let exitAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Animasyon için state
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // Arka plan overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .opacity(opacity)
                .onTapGesture {
                    // Dışarı tıklanınca kapat - opsiyonel
                }
            
            // Alert kutusu
            VStack(spacing: 16) {
                // Üst kısım - Başlık ve ikon (ortalanmış)
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.red)
                    
                    Text("Bağlantı Hatası")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                Divider()
                
                // Mesaj
                Text("Rüya Günlüğü internet bağlantısı gerektiriyor.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Asıl mesaj
                Text("Lütfen bağlantınızı kontrol edip tekrar deneyin.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                // Buton
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        opacity = 0
                        scale = 0.8
                    }
                    
                    // Delay ve çıkış
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        exitAction()
                    }
                }) {
                    Text("Tamam")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(NetworkAlertButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .frame(width: min(UIScreen.main.bounds.width - 60, 300))
            .background(
                colorScheme == .dark ?
                Color(UIColor.systemGray6) :
                    Color(UIColor.systemBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

// Özel buton stili
struct NetworkAlertButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if configuration.isPressed {
                        colorScheme == .dark ?
                        Color(UIColor.systemRed).opacity(0.7) :
                        Color(UIColor.systemRed).opacity(0.7)
                    } else {
                        colorScheme == .dark ?
                        Color(UIColor.systemRed) :
                        Color(UIColor.systemRed)
                    }
                }
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
