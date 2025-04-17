import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Görünüm")) {
                    Toggle("Karanlık Mod", isOn: $viewModel.isDarkModeEnabled)
                        .onChange(of: viewModel.isDarkModeEnabled) { newValue in
                            viewModel.saveSettings()
                            // Tema değişikliğinin hemen görülebilmesi için animasyon ekle
                            withAnimation {
                                // ViewModel içindeki didSet zaten tema değişikliğini uygulayacak
                            }
                        }
                }
                
                Section(header: Text("Bildirimler")) {
                    Toggle("Günlük Hatırlatıcılar", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { _ in
                            viewModel.saveSettings()
                            viewModel.updateNotifications()
                        }
                    
                    if viewModel.notificationsEnabled {
                        DatePicker("Hatırlatma Zamanı", selection: $viewModel.notificationTime, displayedComponents: .hourAndMinute)
                            .onChange(of: viewModel.notificationTime) { _ in
                                viewModel.saveSettings()
                                viewModel.updateNotifications()
                            }
                    }
                }
                
                Section(header: Text("Görsel Tercihleri")) {
                    Picker("Görsel Stili", selection: $viewModel.userPromptPreference) {
                        Text("Gerçekçi").tag("Gerçekçi")
                        Text("Sanatsal").tag("Sanatsal")
                        Text("Soyut").tag("Soyut")
                        Text("Anime").tag("Anime")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.userPromptPreference) { _ in
                        viewModel.saveSettings()
                    }
                    
                    Toggle("Görselleri Fotoğraflara Kaydet", isOn: $viewModel.saveImagesInPhotos)
                        .onChange(of: viewModel.saveImagesInPhotos) { _ in
                            viewModel.saveSettings()
                        }
                }
                
                Section(header: Text("Hakkında")) {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Gizlilik Politikası")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        // Bu modifier uygulama görünümünün tema değişikliklerine duyarlı olmasını sağlar
        .preferredColorScheme(viewModel.isDarkModeEnabled ? .dark : .light)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
