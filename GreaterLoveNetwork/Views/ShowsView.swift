import SwiftUI

// MARK: - Shows View (replaces CategoriesView)
struct ShowsView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    @State private var selectedShow: Show?
    @State private var showingShowDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header Section
            headerSection
            
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 80) {
                    // Continue Watching Section (if any)
                    if !progressManager.getContinueWatchingVideos().isEmpty {
                        continueWatchingSection
                    }
                    
                    // Featured Shows
                    featuredShowsSection
                    
                    // Shows by Category
                    showsByCategorySection
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 100)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingVideoPlayer) {
            if let stream = selectedContent as? LiveStream {
                LiveTVPlayerView(stream: stream)
            } else if let episode = selectedContent as? Episode {
                VideoDataPlayerView(videoData: convertEpisodeToVideoData(episode))
            }
        }
        .sheet(isPresented: $showingShowDetail) {
            if let show = selectedShow {
                ShowDetailView(show: show) { episode in
                    selectedContent = episode
                    showingShowDetail = false
                    showingVideoPlayer = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 30) {
            Spacer()
                .frame(height: 40)
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DISCOVER")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("ALL SHOWS")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Statistics Card
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 15) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("\(apiService.shows.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Shows")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 40)
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("\(apiService.allEpisodes.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Episodes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 80)
        }
        .frame(height: 180)
        .background(Color.black.opacity(0.98))
    }
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("Continue Watching")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    progressManager.clearAllProgress()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Clear All")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(progressManager.getContinueWatchingVideos()) { progress in
                        if let episode = findEpisode(by: progress.videoId) {
                            ContinueWatchingCard(
                                videoData: convertEpisodeToVideoData(episode),
                                watchProgress: progress
                            ) {
                                selectedContent = episode
                                showingVideoPlayer = true
                            }
                            .environmentObject(apiService)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var featuredShowsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("Featured Shows")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Most active shows")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.shows.isEmpty {
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: ShowCategory.allCases[index % ShowCategory.allCases.count].color)
                        }
                    } else {
                        // Show top 6 shows with most episodes
                        let featuredShows = apiService.shows
                            .sorted { $0.episodeCount > $1.episodeCount }
                            .prefix(6)
                        
                        ForEach(Array(featuredShows)) { show in
                            FeaturedShowCard(show: show) {
                                selectedShow = show
                                showingShowDetail = true
                            }
                            .environmentObject(apiService)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var showsByCategorySection: some View {
        VStack(alignment: .leading, spacing: 50) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "tv.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Browse by Category")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Organized by content type")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if apiService.isLoading || apiService.showCollections.isEmpty {
                // Loading State
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(0..<9, id: \.self) { index in
                        LoadingShowCategoryCard(index: index)
                    }
                }
            } else {
                // Shows by Category
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(apiService.showCollections) { collection in
                        ShowCategoryCard(collection: collection) {
                            // Show category detail or first show
                            if let firstShow = collection.shows.first {
                                selectedShow = firstShow
                                showingShowDetail = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findEpisode(by episodeId: String) -> Episode? {
        return apiService.allEpisodes.first { $0._id == episodeId }
    }
    
    private func convertEpisodeToVideoData(_ episode: Episode) -> VideoData {
        return VideoData(
            dataId: episode.episodeId,
            fileName: episode.fileName,
            enabled: episode.enabled,
            bytes: episode.bytes,
            mediaInfo: episode.mediaInfo,
            encodingRequired: episode.encodingRequired,
            precedence: episode.precedence,
            author: episode.author,
            creationTime: episode.creationTime,
            _id: episode._id,
            playback: VideoPlayback(
                embed_url: episode.playback?.embed_url,
                hls_url: episode.playback?.hls_url
            )
        )
    }
}

// MARK: - Featured Show Card
struct FeaturedShowCard: View {
    let show: Show
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    // Show thumbnail or gradient background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    show.showCategory.color.opacity(0.9),
                                    show.showCategory.color.opacity(0.6),
                                    show.showCategory.color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 380, height: 220)
                        .overlay(
                            VStack(spacing: 16) {
                                // Show icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: show.showCategory.icon)
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 8) {
                                    Text(show.displayName)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    
                                    HStack(spacing: 12) {
                                        Image(systemName: "tv.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text("\(show.episodeCount) episodes")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(24)
                        )
                    
                    // Focus indicator
                    if isFocused {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 380, height: 220)
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(
                    color: isFocused ? .white.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 12 : 6,
                    x: 0,
                    y: isFocused ? 8 : 4
                )
                
                // Show info
                VStack(spacing: 8) {
                    Text(show.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(show.showCategory.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }
}

// MARK: - Show Category Card
struct ShowCategoryCard: View {
    let collection: ShowCollection
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    collection.category.color.opacity(0.9),
                                    collection.category.color.opacity(0.7),
                                    collection.category.color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 340, height: 200)
                        .overlay(
                            VStack(spacing: 16) {
                                // Category icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: collection.category.icon)
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 8) {
                                    Text(collection.displayTitle)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    
                                    VStack(spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "tv.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Text("\(collection.showCount) shows")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Text("\(collection.totalEpisodes) episodes")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(24)
                        )
                    
                    if isFocused {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 340, height: 200)
                    }
                }
                .scaleEffect(isFocused ? 1.08 : 1.0)
                .shadow(
                    color: isFocused ? .white.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 12 : 6,
                    x: 0,
                    y: isFocused ? 8 : 4
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }
}

// MARK: - Loading Show Category Card
struct LoadingShowCategoryCard: View {
    let index: Int
    @State private var isAnimating = false
    
    private var loadingColors: [Color] {
        ShowCategory.allCases.map { $0.color }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            loadingColors[index % loadingColors.count].opacity(0.6),
                            loadingColors[index % loadingColors.count].opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 340, height: 200)
                .overlay(
                    VStack(spacing: 16) {
                        // Animated loading circle
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            )
                        
                        VStack(spacing: 8) {
                            // Loading title placeholder
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 140, height: 20)
                            
                            // Loading subtitle placeholder
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 100, height: 16)
                        }
                    }
                )
                .scaleEffect(isAnimating ? 1.02 : 1.0)
                .opacity(isAnimating ? 0.8 : 1.0)
        }
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                isAnimating = true
            }
        }
    }
}
