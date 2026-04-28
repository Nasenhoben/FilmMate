import Foundation
import SwiftUI

@MainActor
final class MovieViewModel: ObservableObject {
    @Published var selectedGenres: Set<Genre> = []
    @Published var selectedProviders: Set<StreamingProvider> = []
    @Published var suggestedMovies: [Movie] = []
    @Published var isLoading = false
    @Published var updateProgress: Double = 0
    @Published var updateStatusText: String = ""
    @Published var isUpdating = false
    @Published var updateError: String?
    @Published var showUpdateError = false
    @Published var showSettings = false
    @Published var updateComplete = false

    private let db = DatabaseService.shared

    var filteredMovies: [Movie] {
        db.movies(genres: selectedGenres, providers: selectedProviders)
    }

    var filteredCount: Int { filteredMovies.count }

    var hasDatabase: Bool { !db.isEmpty }

    var lastUpdated: Date? { db.lastUpdated }

    func toggleGenre(_ genre: Genre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        suggestedMovies = []
    }

    func toggleProvider(_ provider: StreamingProvider) {
        if selectedProviders.contains(provider) {
            selectedProviders.remove(provider)
        } else {
            selectedProviders.insert(provider)
        }
        suggestedMovies = []
    }

    func suggestRandom() {
        guard filteredCount > 0 else { return }
        let previous = Set(suggestedMovies.map(\.id))
        var pool = filteredMovies.filter { !previous.contains($0.id) }
        if pool.count < 5 { pool = filteredMovies }
        suggestedMovies = Array(pool.shuffled().prefix(5))
    }

    func clearFilters() {
        selectedGenres = []
        selectedProviders = []
        suggestedMovies = []
    }

    func updateDatabase() async {
        guard !isUpdating else { return }
        isUpdating = true
        updateProgress = 0
        updateError = nil
        updateComplete = false

        do {
            let movies = try await TMDBService.shared.fetchMoviesWithProviders { [weak self] progress, status in
                // Already dispatched to main queue by ProgressCounter — set directly
                self?.updateProgress = progress
                self?.updateStatusText = status
            }
            // Defer save to next run loop so it never lands inside a render pass
            DispatchQueue.main.async { [weak self] in
                self?.db.save(movies)
                self?.updateComplete = true
                self?.isUpdating = false
            }
        } catch {
            updateError = error.localizedDescription
            showUpdateError = true
            isUpdating = false
        }
    }
}
