import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Arama çubuğu
                searchBar
                
                // Etiket listesi
                tagsList
                
                // Sonuçlar
                List {
                    if viewModel.isSearching {
                        ProgressView("Aranıyor...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowSeparator(.hidden)
                    } else if viewModel.searchResults.isEmpty {
                        emptyResultsView
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(viewModel.searchResults) { dream in
                            NavigationLink(destination: DreamDetailView(dream: dream)) {
                                DreamRowView(dream: dream)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Ara")
            .onAppear {
                viewModel.loadAllTags()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Rüyalarında ara...", text: $searchText)
                .onSubmit {
                    viewModel.searchDreams(searchText)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
    
    private var tagsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTag == tag {
                            selectedTag = nil
                            viewModel.clearSearch()
                        } else {
                            selectedTag = tag
                            viewModel.searchByTag(tag)
                        }
                    }) {
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTag == tag ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTag == tag ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty || selectedTag != nil {
                Text("Sonuç bulunamadı")
                    .font(.headline)
                
                Text("Farklı anahtar kelimeler veya etiketler deneyin.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else {
                Text("Rüyalarını ara")
                    .font(.headline)
                
                Text("Rüya içeriği, başlık veya etiketlerde arama yapabilirsin.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
