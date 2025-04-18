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

                Section(header: Text("Bilinçli Rüya")) {
                    Toggle("Bilinçli Rüya Hatırlatıcıları", isOn: $viewModel.lucidDreamingEnabled)
                        .onChange(of: viewModel.lucidDreamingEnabled) { _ in
                            viewModel.saveSettings()
                            viewModel.updateNotifications()
                        }

                    if viewModel.lucidDreamingEnabled {
                        DatePicker("Hatırlatma Zamanı", selection: $viewModel.lucidDreamReminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: viewModel.lucidDreamReminderTime) { _ in
                                viewModel.saveSettings()
                                viewModel.updateNotifications()
                            }

                        Picker("Teknik Seçin", selection: $viewModel.selectedLucidTechnique) {
                            ForEach(LucidDreamingTechnique.allCases, id: \.self) { technique in
                                Text(technique.rawValue)
                            }
                        }
                        .onChange(of: viewModel.selectedLucidTechnique) { _ in
                            viewModel.saveSettings()
                        }

                        NavigationLink(destination: LucidDreamingTipsView(technique: viewModel.selectedLucidTechnique)) {
                            Text("Teknik İpuçları")
                        }
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

struct LucidDreamingTipsView: View {
    let technique: LucidDreamingTechnique

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(technique.rawValue) İpuçları")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)

                ForEach(technique.tips, id: \.self) { tip in
                    Text("• \(tip)")
                }
            }
            .padding()
        }
        .navigationTitle("\(technique.rawValue) İpuçları")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
