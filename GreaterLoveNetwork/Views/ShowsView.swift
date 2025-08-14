import SwiftUI

// MARK: - Shows View with Fixed Grid Navigation
struct ShowsView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    @State private var selectedShow: Show?
    @State private var showingShowDetail = false
    
    // Focus management for proper grid navigation
    @FocusState private var focusedShow: String?
    @FocusState private var continueWatchingFocused: Int?
    @State private var gridColumns = 3
    @State private var totalShows = 0
    
    var sortedShows: [Show] {
        return apiService.shows.sorted { $0.episodeCount > $1.episodeCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header Section
            headerSection
            
            // Main Content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 80) {
                        // Continue Watching Section (if any)
                        if !progressManager.getContinueWatchingVideos().isEmpty {
                            continueWatchingSection
                                .id("continue_watching")
                        }
                        
                        // All Shows Grid with Fixed Navigation
                        allShowsGridSection
                            .id("shows_grid")
                        
                        // Load More Section
                        if apiService.hasMorePages && !apiService.isLoadingMoreShows {
                            loadMoreSection
                                .id("load_more")
                                .onAppear {
                                    apiService.loadMoreShows()
                                }
                        }
                        
                        // Loading More Shows Indicator
                        if apiService.isLoadingMoreShows {
                            loadingMoreSection
                                .id("loading_more")
                        }
                        
                        // Pagination Info Section
                        paginationInfoSection
                            .id("pagination_info")
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 100)
                }
                .onAppear {
                    totalShows = sortedShows.count
                }
                .onChange(of: apiService.shows.count) { newCount in
                    totalShows = newCount
                }
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
        .focusable()
        .onMoveCommand { direction in
            if direction == .down {
                // When coming from navigation, go to continue watching or shows grid
                if !progressManager.getContinueWatchingVideos().isEmpty {
                    continueWatchingFocused = 0
                } else if !sortedShows.isEmpty {
                    focusedShow = sortedShows.first?.id.uuidString
                }
            }
        }
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
                
                // Enhanced Statistics Card with Pagination Info
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
                    ForEach(Array(progressManager.getContinueWatchingVideos().enumerated()), id: \.element.id) { index, progress in
                        if let episode = findEpisode(by: progress.videoId) {
                            ContinueWatchingCard(
                                videoData: convertEpisodeToVideoData(episode),
                                watchProgress: progress
                            ) {
                                selectedContent = episode
                                showingVideoPlayer = true
                            }
                            .environmentObject(apiService)
                            .focused($continueWatchingFocused, equals: index)
                            .onMoveCommand { direction in
                                switch direction {
                                case .up:
                                    // Move back to navigation
                                    continueWatchingFocused = nil
                                case .down:
                                    // Move to shows grid
                                    continueWatchingFocused = nil
                                    if !sortedShows.isEmpty {
                                        focusedShow = sortedShows.first?.id.uuidString
                                    }
                                case .left:
                                    if index > 0 {
                                        continueWatchingFocused = index - 1
                                    }
                                case .right:
                                    if index < progressManager.getContinueWatchingVideos().count - 1 {
                                        continueWatchingFocused = index + 1
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var allShowsGridSection: some View {
        VStack(alignment: .leading, spacing: 50) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "tv.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("All Shows")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            
            if apiService.isLoading && apiService.shows.isEmpty {
                // Initial Loading State - Grid of 9 loading cards
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(0..<9, id: \.self) { index in
                        LoadingShowGridCard(index: index)
                    }
                }
            } else {
                // All Shows Grid with Fixed Navigation - 3 columns with actual data
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(Array(sortedShows.enumerated()), id: \.element.id) { index, show in
                        FixedNavigationShowGridCard(
                            show: show,
                            index: index,
                            totalShows: totalShows,
                            gridColumns: gridColumns,
                            isFocused: focusedShow == show.id.uuidString,
                            onNavigateUp: {
                                handleGridNavigationUp(from: index)
                            },
                            onNavigateDown: {
                                handleGridNavigationDown(from: index)
                            },
                            onNavigateLeft: {
                                handleGridNavigationLeft(from: index)
                            },
                            onNavigateRight: {
                                handleGridNavigationRight(from: index)
                            }
                        ) {
                            selectedShow = show
                            showingShowDetail = true
                        }
                        .focused($focusedShow, equals: show.id.uuidString)
                    }
                }
                .onAppear {
                    // Set initial focus to first show if none is focused
                    if focusedShow == nil && !sortedShows.isEmpty {
                        focusedShow = sortedShows.first?.id.uuidString
                    }
                }
            }
        }
    }
    
    // MARK: - Grid Navigation Logic
    
    private func handleGridNavigationUp(from index: Int) {
        // Only move to navigation/continue watching if we're in the top row (first 3 items)
        if index < gridColumns {
            // We're in the top row
            focusedShow = nil
            // Check if there's continue watching content
            if !progressManager.getContinueWatchingVideos().isEmpty {
                continueWatchingFocused = 0
            }
            // Otherwise, focus will go back to navigation (handled by parent)
        } else {
            // Move to the show above in the same column
            let targetIndex = index - gridColumns
            if targetIndex >= 0 && targetIndex < sortedShows.count {
                focusedShow = sortedShows[targetIndex].id.uuidString
            }
        }
    }
    
    private func handleGridNavigationDown(from index: Int) {
        // Move to the show below in the same column
        let targetIndex = index + gridColumns
        if targetIndex < sortedShows.count {
            focusedShow = sortedShows[targetIndex].id.uuidString
        }
        // If no show below, stay at current position
    }
    
    private func handleGridNavigationLeft(from index: Int) {
        // Move to the show on the left
        if index % gridColumns > 0 {
            let targetIndex = index - 1
            focusedShow = sortedShows[targetIndex].id.uuidString
        }
        // If at leftmost column, stay at current position
    }
    
    private func handleGridNavigationRight(from index: Int) {
        // Move to the show on the right
        if (index % gridColumns) < (gridColumns - 1) && (index + 1) < sortedShows.count {
            let targetIndex = index + 1
            focusedShow = sortedShows[targetIndex].id.uuidString
        }
        // If at rightmost column or no show to the right, stay at current position
    }
    
    private var loadMoreSection: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Loading more shows...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Page \(apiService.currentPage + 1) of \(apiService.totalPages)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical, 30)
        }
    }
    
    private var loadingMoreSection: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    
                    Text("Loading more shows...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Page \(apiService.currentPage) of \(apiService.totalPages)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical, 40)
            
            // Loading preview cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 40),
                GridItem(.flexible(), spacing: 40),
                GridItem(.flexible(), spacing: 40)
            ], spacing: 40) {
                ForEach(0..<6, id: \.self) { index in
                    LoadingShowGridCard(index: index)
                }
            }
        }
    }
    
    private var paginationInfoSection: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Manual Load More Button (backup)
                    if apiService.hasMorePages && !apiService.isLoadingMoreShows {
                        Button(action: {
                            apiService.loadMoreShows()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                
                                Text("Load More Shows")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
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

// MARK: - Fixed Navigation Show Grid Card Component
struct FixedNavigationShowGridCard: View {
    let show: Show
    let index: Int
    let totalShows: Int
    let gridColumns: Int
    let isFocused: Bool
    let onNavigateUp: () -> Void
    let onNavigateDown: () -> Void
    let onNavigateLeft: () -> Void
    let onNavigateRight: () -> Void
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    // Show background with category color and enhanced styling
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    show.showCategory.color.opacity(0.9),
                                    show.showCategory.color.opacity(0.7),
                                    show.showCategory.color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 340, height: 200)
                        .overlay(
                            // Subtle pattern overlay
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 150
                                    )
                                )
                        )
                        .overlay(
                            // Episode count badge in top right
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    Text("\(show.episodeCount)")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(12)
                                        .padding(12)
                                }
                                Spacer()
                            }
                        )
                    
                    // Content overlay
                    VStack(spacing: 16) {
                        // Show icon with background
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: show.showCategory.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            // Show title
                            Text(show.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            // Category badge
                            Text(show.showCategory.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(24)
                    
                    // Enhanced focus indicator
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
                
                // Show info below card
                VStack(spacing: 8) {
                    Text(show.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("\(show.episodeCount) episodes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        if let latestEpisode = show.latestEpisode,
                           let duration = latestEpisode.mediaInfo?.durationMins {
                            Text("•")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("~\(duration) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.25), value: isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .up:
                onNavigateUp()
            case .down:
                onNavigateDown()
            case .left:
                onNavigateLeft()
            case .right:
                onNavigateRight()
            default:
                break
            }
        }
    }
}

// MARK: - Enhanced Loading Show Grid Card
struct LoadingShowGridCard: View {
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
            
            // Loading text below
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 14)
            }
        }
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                isAnimating = true
            }
        }
    }
}
