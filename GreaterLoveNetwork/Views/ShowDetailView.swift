import SwiftUI

// MARK: - Show Detail View
struct ShowDetailView: View {
    let show: Show
    let onEpisodeSelect: (Episode) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var sortOrder: EpisodeSortOrder = .newest
    @State private var showSortOptions = false
    
    enum EpisodeSortOrder: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case episodeNumber = "Episode Number"
        case alphabetical = "A-Z"
        
        var icon: String {
            switch self {
            case .newest: return "calendar.badge.minus"
            case .oldest: return "calendar.badge.plus"
            case .episodeNumber: return "list.number"
            case .alphabetical: return "textformat"
            }
        }
    }
    
    var sortedEpisodes: [Episode] {
        let enabledEpisodes = show.episodes.filter { $0.enabled }
        
        switch sortOrder {
        case .newest:
            return enabledEpisodes.sorted { episode1, episode2 in
                let dateFormatter = ISO8601DateFormatter()
                let date1 = dateFormatter.date(from: episode1.creationTime) ?? Date.distantPast
                let date2 = dateFormatter.date(from: episode2.creationTime) ?? Date.distantPast
                return date1 > date2
            }
        case .oldest:
            return enabledEpisodes.sorted { episode1, episode2 in
                let dateFormatter = ISO8601DateFormatter()
                let date1 = dateFormatter.date(from: episode1.creationTime) ?? Date.distantPast
                let date2 = dateFormatter.date(from: episode2.creationTime) ?? Date.distantPast
                return date1 < date2
            }
        case .episodeNumber:
            return enabledEpisodes.sorted { episode1, episode2 in
                let num1 = episode1.episodeNumber ?? 0
                let num2 = episode2.episodeNumber ?? 0
                return num1 < num2
            }
        case .alphabetical:
            return enabledEpisodes.sorted { $0.displayTitle < $1.displayTitle }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header
            showDetailHeader
            
            // Episodes List
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30)
                ], spacing: 40) {
                    ForEach(sortedEpisodes) { episode in
                        EpisodeCard(episode: episode, show: show) {
                            onEpisodeSelect(episode)
                        }
                        .environmentObject(apiService)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.vertical, 40)
            }
            .background(Color.black.opacity(0.95))
        }
        .background(Color.black)
        .ignoresSafeArea(.all)
    }
    
    private var showDetailHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation and close button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Sort Options Button
                Button(action: {
                    showSortOptions.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: sortOrder.icon)
                            .font(.system(size: 16))
                        Text(sortOrder.rawValue)
                            .font(.system(size: 16, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showSortOptions) {
                    sortOptionsPopover
                }
            }
            .padding(.horizontal, 60)
            .padding(.top, 50)
            .padding(.bottom, 30)
            
            // Show info section
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        // Show icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: show.showCategory.icon)
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(show.displayName)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(show.showCategory.rawValue)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(show.showCategory.color)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(show.showCategory.color.opacity(0.2))
                                .cornerRadius(12)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 8) {
                                    Image(systemName: "tv.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("\(show.episodeCount)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(show.episodeCount == 1 ? "episode" : "episodes")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Text("•")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                if let latestEpisode = show.latestEpisode,
                                   let duration = latestEpisode.mediaInfo?.durationMins {
                                    Text("~\(duration) min episodes")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    
                    // Continue watching episodes for this show
                    if let continueWatchingEpisodes = getContinueWatchingForShow() {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Continue Watching")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(continueWatchingEpisodes) { progress in
                                        if let episode = show.episodes.first(where: { $0._id == progress.videoId }) {
                                            CompactContinueWatchingCard(episode: episode, progress: progress) {
                                                onEpisodeSelect(episode)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [
                    show.showCategory.color.opacity(0.9),
                    show.showCategory.color.opacity(0.7),
                    show.showCategory.color.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var sortOptionsPopover: some View {
        VStack(spacing: 0) {
            ForEach(EpisodeSortOrder.allCases, id: \.self) { option in
                Button(action: {
                    sortOrder = option
                    showSortOptions = false
                }) {
                    HStack {
                        Image(systemName: option.icon)
                            .font(.system(size: 16))
                            .foregroundColor(sortOrder == option ? .blue : .primary)
                        
                        Text(option.rawValue)
                            .font(.system(size: 16, weight: sortOrder == option ? .semibold : .medium))
                            .foregroundColor(sortOrder == option ? .blue : .primary)
                        
                        Spacer()
                        
                        if sortOrder == option {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(sortOrder == option ? Color.blue.opacity(0.1) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                if option != EpisodeSortOrder.allCases.last {
                    Divider()
                }
            }
        }
        .frame(width: 200)
        .background(Color.black.opacity(0.9))
        .cornerRadius(8)
        .shadow(radius: 8)
    }
    
    // MARK: - Helper Methods
    
    private func getContinueWatchingForShow() -> [WatchProgress]? {
        let showEpisodeIds = Set(show.episodes.map { $0._id })
        let continueWatching = progressManager.getContinueWatchingVideos()
            .filter { showEpisodeIds.contains($0.videoId) }
        
        return continueWatching.isEmpty ? nil : continueWatching
    }
}

// MARK: - Episode Card
struct EpisodeCard: View {
    let episode: Episode
    let show: Show
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @FocusState private var isFocused: Bool
    
    private var watchProgress: WatchProgress? {
        progressManager.getProgress(for: episode._id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    Group {
                        switch apiService.thumbnailStates[episode._id] {
                        case .loading:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 300, height: 170)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                )
                        case .loaded(let image):
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 300, height: 170)
                                .clipped()
                        case .failed, .none:
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            show.showCategory.color.opacity(0.8),
                                            show.showCategory.color.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 300, height: 170)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                        
                                        if let episodeNum = episode.episodeNumber {
                                            Text("Ep \(episodeNum)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                        
                                        if let duration = episode.mediaInfo?.durationMins {
                                            Text("\(duration) min")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                )
                        }
                    }
                    .cornerRadius(12)
                    
                    // Progress bar overlay if episode has been watched
                    if let progress = watchProgress {
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 0) {
                                // Progress bar
                                GeometryReader { geo in
                                    HStack {
                                        Rectangle()
                                            .fill(Color.orange)
                                            .frame(width: geo.size.width * CGFloat(progress.progressPercentage / 100))
                                        
                                        Spacer()
                                    }
                                }
                                .frame(height: 4)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(2)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    
                    // Episode number badge (top-left)
                    if let episodeNum = episode.episodeNumber {
                        VStack {
                            HStack {
                                Text("EP \(episodeNum)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(6)
                                    .padding(8)
                                
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    
                    // Play button and continue indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                                
                                if watchProgress != nil {
                                    Text("Continue")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(color: isFocused ? show.showCategory.color.opacity(0.5) : .clear, radius: 8)
                
                // Episode title and info
                VStack(spacing: 8) {
                    Text(episode.displayTitle)
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                    
                    HStack(spacing: 8) {
                        if let progress = watchProgress {
                            Text("\(Int(progress.progressPercentage))% watched")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("•")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("\(progress.formattedRemainingTime) left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        } else if let duration = episode.mediaInfo?.durationMins {
                            Text("\(duration) min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        if let airDate = episode.airDate {
                            if watchProgress == nil {
                                Text("•")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            
                            Text(DateFormatter.episodeDate.string(from: airDate))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .onAppear {
            if apiService.thumbnailStates[episode._id] == nil {
                apiService.loadThumbnail(for: episode)
            }
        }
    }
}

// MARK: - Compact Continue Watching Card
struct CompactContinueWatchingCard: View {
    let episode: Episode
    let progress: WatchProgress
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Mini thumbnail
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 60, height: 34)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(Int(progress.progressPercentage))% • \(progress.formattedRemainingTime) left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .scaleEffect(isFocused ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
