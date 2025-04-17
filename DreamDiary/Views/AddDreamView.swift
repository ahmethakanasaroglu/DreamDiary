import SwiftUI

struct AddDreamView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DreamListViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, content, tags
    }
    
    @State private var title = ""
    @State private var content = ""
    @State private var mood: Dream.DreamMood = .neutral
    @State private var tags = ""
    @State private var date = Date()
    @State private var isSaving = false
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rüya Detayları")) {
                    TextField("Başlık", text: $title)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .content
                        }
                    
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    
                    moodSelector
                }
                
                Section(header: Text("Rüya İçeriği")) {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Rüyanı buraya yaz...")
                                .autocorrectionDisabled()
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $content)
                            .focused($focusedField, equals: .content)
                            .frame(minHeight: 200)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .tags
                            }
                    }
                }
                
                Section(header: Text("Etiketler"), footer: Text("Etiketleri virgülle ayırın. Örn: uçmak, ev, korku")) {
                    TextField("Etiketler", text: $tags)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .tags)
                        .submitLabel(.done)
                }
                
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            Text("Formu Temizle")
                                .foregroundColor(.red)
                        }
                        .disabled(title.isEmpty && content.isEmpty && tags.isEmpty)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Yeni Rüya")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            isSaving = true
                            saveDream()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.blue)
                        } else {
                            Text("Kaydet")
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        
                        Button("Tamam") {
                            focusedField = nil
                        }
                    }
                }
            }
            .alert("Formu Temizle", isPresented: $showingClearConfirmation) {
                Button("İptal", role: .cancel) { }
                Button("Temizle", role: .destructive) {
                    title = ""
                    content = ""
                    tags = ""
                    mood = .neutral
                    date = Date()
                }
            } message: {
                Text("Tüm girdiğiniz bilgiler silinecek. Emin misiniz?")
            }
            .onAppear {
                // Otomatik olarak başlık alanına odaklan
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .title
                }
            }
        }
    }
    
    private var moodSelector: some View {
        VStack(alignment: .leading) {
            Text("Duygu Durumu")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Dream.DreamMood.allCases, id: \.self) { moodOption in
                        Button {
                            withAnimation {
                                mood = moodOption
                            }
                        } label: {
                            VStack {
                                Text(moodOption.emoji)
                                    .font(.system(size: 30))
                                
                                Text(moodOption.rawValue)
                                    .font(.caption)
                                    .foregroundColor(mood == moodOption ? .primary : .secondary)
                            }
                            .frame(width: 60, height: 65)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(mood == moodOption ? Color.blue.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    private func saveDream() {
        let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let newDream = Dream(
            title: title,
            content: content,
            date: date,
            mood: mood,
            tags: tagArray
        )
        
        // İşlem tamamlandığında animasyon ile kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.addDream(newDream)
            dismiss()
        }
    }
}
