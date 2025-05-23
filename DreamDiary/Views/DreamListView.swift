import SwiftUI

struct DreamListView: View {
    @EnvironmentObject var dreamListViewModel: DreamListViewModel
    @State private var showingAddDream = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if dreamListViewModel.dreams.isEmpty {
                    Text("Henüz hiç rüya eklenmemiş.")
                        .foregroundColor(.secondary)
                        .font(.title3)
                        .padding()
                } else {
                    List {
                        ForEach(dreamListViewModel.dreams) { dream in
                            NavigationLink(destination: DreamDetailView(dream: dream)) {
                                DreamRowView(dream: dream)
                            }
                        }
                        .onDelete(perform: dreamListViewModel.deleteDream)
                    }
                }
            }
            .navigationTitle("Rüya Günlüğüm")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDream = true
                    }) {
                        Label("Yeni Rüya", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Label("Ayarlar", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddDream) {
                AddDreamView(viewModel: dreamListViewModel)
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                // View görünür olduğunda rüyaları yükle
                dreamListViewModel.loadDreams()
            }
        }
    }
}

struct DreamRowView: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dream.title)
                    .font(.headline)
                Spacer()
                Text(dream.mood.emoji)
                    .font(.title2)
            }

            Text(dream.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)

            HStack {
                Text(dream.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                ForEach(dream.tags.prefix(3), id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DreamListView_Previews: PreviewProvider {
    static var previews: some View {
        DreamListView()
            .environmentObject(DreamListViewModel())
    }
}
