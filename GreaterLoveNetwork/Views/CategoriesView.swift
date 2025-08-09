import SwiftUI

// MARK: - Enhanced Categories View with Better Organization
struct CategoriesView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    @State private var selectedCategory: Category?
    @State private var showingCategoryDetail = false
    
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
                    
                    // Categories Grid with better organization
                    categoriesGridSection
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
            } else if let videoData = selectedContent as? VideoData {
                VideoDataPlayerView(videoData: videoData)
            } else if let episode = selectedContent as? Episode {
                VideoDataPlayerView(videoData: convertEpisodeToVideoData(episode))
            }
        }
        .sheet(isPresented: $showingCategoryDetail) {
            if let category = selectedCategory {
                CategoryDetailView(category: category) { videoData in
                    selectedContent = videoData
                    showingCategoryDetail = false
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
                    Text("EXPLORE")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("ALL CATEGORIES")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Statistics Card
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 15) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("\(apiService.categories.count)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Categories")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 40)
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("\(getTotalVideoCount())")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Videos")
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
                        if let videoData = findVideoData(by: progress.videoId) {
                            ContinueWatchingCard(
                                videoData: videoData,
                                watchProgress: progress
                            ) {
                                selectedContent = videoData
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
    
    private var categoriesGridSection: some View {
        VStack(alignment: .leading, spacing: 50) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Browse by Category")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Tap any category to explore")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if apiService.isLoading || apiService.categories.isEmpty {
                // Enhanced Loading State
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(0..<9, id: \.self) { index in
                        EnhancedLoadingCategoryCard(index: index)
                    }
                }
            } else {
                // Enhanced Categories Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40),
                    GridItem(.flexible(), spacing: 40)
                ], spacing: 40) {
                    ForEach(apiService.categories) { category in
                        EnhancedCategoryCard(category: category) {
                            selectedCategory = category
                            showingCategoryDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findVideoData(by videoId: String) -> VideoData? {
        // First try to find in the legacy videoData array
        if let videoData = apiService.videoData.first(where: { $0._id == videoId }) {
            return videoData
        }
        
        // If not found, try to find in episodes and convert
        if let episode = apiService.allEpisodes.first(where: { $0._id == videoId }) {
            return convertEpisodeToVideoData(episode)
        }
        
        return nil
    }
    
    private func getTotalVideoCount() -> Int {
        // Return the total count from both videoData and allEpisodes, avoiding duplicates
        let videoDataIds = Set(apiService.videoData.map { $0._id })
        let episodeIds = Set(apiService.allEpisodes.map { $0._id })
        
        // Use the larger count or combine if they're different data sets
        return max(videoDataIds.count, episodeIds.count)
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

// MARK: - Enhanced Category Card Component
struct EnhancedCategoryCard: View {
    let category: Category
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    // Enhanced background with multiple gradients
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    category.color.opacity(0.9),
                                    category.color.opacity(0.7),
                                    category.color.opacity(0.8)
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
                    
                    // Content overlay with better spacing
                    VStack(spacing: 16) {
                        // Category icon with background
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            getCategoryIcon(for: category.name)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            // Category title
                            Text(category.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            
                            // Enhanced video count with icon
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("\(category.videos.count) videos")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
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
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
    }
    
    private func getCategoryIcon(for categoryName: String) -> Image {
        switch categoryName {
        case "All Videos":
            return Image(systemName: "square.grid.3x3")
        case "Recently Added":
            return Image(systemName: "calendar.badge.plus")
        case "Ministries & Churches":
            return Image(systemName: "building.2.crop.circle")
        case "Biblical Teaching":
            return Image(systemName: "book.closed")
        case "Inspirational & Testimony":
            return Image(systemName: "heart.circle.fill")
        case "Biblical Studies":
            return Image(systemName: "text.book.closed")
        case "Faith & Worship":
            return Image(systemName: "hands.sparkles.fill")
        case "Series & Shows":
            return Image(systemName: "tv.circle")
        default:
            return Image(systemName: "folder.circle")
        }
    }
}

// MARK: - Enhanced Loading Category Card
struct EnhancedLoadingCategoryCard: View {
    let index: Int
    @State private var isAnimating = false
    
    private var loadingColors: [Color] {
        [.blue, .purple, .green, .orange, .red, .cyan, .pink, .indigo, .mint]
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

// MARK: - Category Detail View with Enhanced UI
struct CategoryDetailView: View {
    let category: Category
    let onVideoSelect: (VideoData) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var apiService: CastrAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Header
            categoryDetailHeader
            
            // Videos Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30),
                    GridItem(.flexible(), spacing: 30)
                ], spacing: 40) {
                    ForEach(category.videos) { video in
                        VideoDataCard(videoData: video) {
                            onVideoSelect(video)
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
    
    private var categoryDetailHeader: some View {
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
            }
            .padding(.horizontal, 60)
            .padding(.top, 50)
            .padding(.bottom, 30)
            
            // Category info section
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            getCategoryIcon(for: category.name)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.name)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                Text("\(category.videos.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(category.videos.count == 1 ? "video" : "videos")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("•")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("Ready to watch")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
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
                    category.color.opacity(0.9),
                    category.color.opacity(0.7),
                    category.color.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func getCategoryIcon(for categoryName: String) -> Image {
        switch categoryName {
        case "All Videos":
            return Image(systemName: "square.grid.3x3")
        case "Recently Added":
            return Image(systemName: "calendar.badge.plus")
        case "Ministries & Churches":
            return Image(systemName: "building.2.crop.circle")
        case "Biblical Teaching":
            return Image(systemName: "book.closed")
        case "Inspirational & Testimony":
            return Image(systemName: "heart.circle.fill")
        case "Biblical Studies":
            return Image(systemName: "text.book.closed")
        case "Faith & Worship":
            return Image(systemName: "hands.sparkles.fill")
        case "Series & Shows":
            return Image(systemName: "tv.circle")
        default:
            return Image(systemName: "folder.circle")
        }
    }
}
