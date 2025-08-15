import SwiftUI

// MARK: - Enhanced Home View with Fixed Live Streaming
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    @State private var selectedShow: Show?
    @State private var showingShowDetail = false
    @State private var selectedLiveStream: LiveStream?
    @State private var showingLivePlayer = false
    
    // Focus states for navigation - matching UI hierarchy
    @FocusState private var smartCTAFocused: Bool
    @FocusState private var continueWatchingFocused: Int?
    @FocusState private var liveStreamsFocused: Int?
    @FocusState private var featuredShowsFocused: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            ScrollView {
                VStack(spacing: 80) {
                    // Show continue watching section only if there are videos in progress
                    if !progressManager.getContinueWatchingVideos().isEmpty {
                        continueWatchingSection
                    }
                    
                    // Live Streams Section
                    liveStreamsSection
                    
                    // Featured Shows Section
                    featuredShowsSection
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 100)
            }
            .background(Color.black.opacity(0.8))
        }
        .focusable()
        .onMoveCommand { direction in
            if direction == .down {
                // When coming from navigation, focus should go to Smart CTA button first
                smartCTAFocused = true
            }
        }
        .sheet(isPresented: $showingLivePlayer) {
            if let stream = selectedLiveStream {
                LiveTVPlayerView(stream: stream)
            }
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let episode = selectedContent as? Episode {
                VideoDataPlayerView(videoData: convertEpisodeToVideoData(episode))
            } else if let videoData = selectedContent as? VideoData {
                VideoDataPlayerView(videoData: videoData)
            }
        }
        .sheet(isPresented: $showingShowDetail) {
            if let show = selectedShow {
                ShowDetailView(show: show) { episode in
                    selectedContent = episode
                    showingShowDetail = false
                    showingVideoPlayer = true
                }
                .environmentObject(apiService)
            }
        }
        .onAppear {
            // Refresh progress manager when view appears
            progressManager.objectWillChange.send()
        }
    }
    
    private func clearAllContentFocus() {
        smartCTAFocused = false
        continueWatchingFocused = nil
        liveStreamsFocused = nil
        featuredShowsFocused = nil
    }
    
    private func headerSection() -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MEET OUR")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("INSPIRING")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                                .padding(.top, -10)
                            
                            Text("MINISTERS")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                                .padding(.top, -10)
                        }
                        
                        Text("IN ONE PLACE")
                            .font(.custom("Poppins-Medium", size: 32))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        // Smart CTA Button that adapts based on user's watch history
                        smartCTAButton
                            .padding(.top, 50)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
            }
        }
        .frame(height: 500)
    }
    
    private var smartCTAButton: some View {
        let hasWatchHistory = !progressManager.getContinueWatchingVideos().isEmpty
        let buttonTitle = hasWatchHistory ? "Continue Watching" : "Start Exploring"
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.5)) {
                if hasWatchHistory,
                   let firstVideo = progressManager.getContinueWatchingVideos().first,
                   let episode = findEpisode(by: firstVideo.videoId) {
                    selectedContent = episode
                    showingVideoPlayer = true
                } else if let firstShow = apiService.getFeaturedShows().first {
                    selectedShow = firstShow
                    showingShowDetail = true
                }
            }
        }) {
            Text(buttonTitle)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.9, green: 0.2, blue: 0.2))
                )
                .scaleEffect(smartCTAFocused ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($smartCTAFocused)
        .animation(.easeInOut(duration: 0.1), value: smartCTAFocused)
        .onMoveCommand { direction in
            switch direction {
            case .down:
                smartCTAFocused = false
                // Next focus depends on what content exists
                if !progressManager.getContinueWatchingVideos().isEmpty {
                    continueWatchingFocused = 0
                } else {
                    liveStreamsFocused = 0
                }
            case .up:
                smartCTAFocused = false
                // Move back to navigation - will be handled by parent
            default:
                break
            }
        }
    }
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("Continue Watching")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    progressManager.clearAllProgress()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Clear All")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
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
                                    continueWatchingFocused = nil
                                    smartCTAFocused = true
                                case .down:
                                    continueWatchingFocused = nil
                                    liveStreamsFocused = 0
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
    
    // MARK: - Live Streams Section with Fixed Navigation
    private var liveStreamsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    
                    Text("Live Streams")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                    
                    Text("Live now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 60) {
                if apiService.isLoading || apiService.liveStreams.isEmpty {
                    LoadingLiveStreamCard(number: "1", subtitle: "Greater Love TV I")
                    LoadingLiveStreamCard(number: "2", subtitle: "Greater Love TV II")
                } else {
                    ForEach(Array(apiService.liveStreams.prefix(2).enumerated()), id: \.element.id) { index, stream in
                        EnhancedLiveStreamCard(
                            stream: stream,
                            number: "\(index + 1)",
                            subtitle: "Greater Love TV \(index == 0 ? "I" : "II")",
                            imageName: index == 0 ? "GL_live_1" : "GL_live_2"
                        ) {
                            // Fixed: Use separate state for live stream player
                            selectedLiveStream = stream
                            showingLivePlayer = true
                        }
                        .focused($liveStreamsFocused, equals: index)
                        .onMoveCommand { direction in
                            switch direction {
                            case .up:
                                liveStreamsFocused = nil
                                // Go back to continue watching if it exists, otherwise to Smart CTA
                                if !progressManager.getContinueWatchingVideos().isEmpty {
                                    continueWatchingFocused = 0
                                } else {
                                    smartCTAFocused = true
                                }
                            case .down:
                                liveStreamsFocused = nil
                                featuredShowsFocused = 0
                            case .left:
                                if index > 0 {
                                    liveStreamsFocused = index - 1
                                }
                            case .right:
                                if index < 1 { // Only 2 live streams (0 and 1)
                                    liveStreamsFocused = index + 1
                                }
                            default:
                                break
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Featured Shows Section
    private var featuredShowsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("Featured Shows")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Handpicked content")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 50) {
                    if apiService.isLoading || apiService.featuredShows.isEmpty {
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: getFeaturedShowColors()[index])
                        }
                    } else {
                        ForEach(Array(apiService.getFeaturedShows().enumerated()), id: \.element.id) { index, show in
                            let colors: [Color] = getFeaturedShowColors()
                            FeaturedShowCard(
                                show: show,
                                color: colors[index % colors.count]
                            ) {
                                selectedShow = show
                                showingShowDetail = true
                            }
                            .environmentObject(apiService)
                            .focused($featuredShowsFocused, equals: index)
                            .onMoveCommand { direction in
                                switch direction {
                                case .up:
                                    featuredShowsFocused = nil
                                    liveStreamsFocused = 0
                                case .left:
                                    if index > 0 {
                                        featuredShowsFocused = index - 1
                                    }
                                case .right:
                                    if index < apiService.getFeaturedShows().count - 1 {
                                        featuredShowsFocused = index + 1
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
    
    // MARK: - Helper Methods
    
    private func findEpisode(by episodeId: String) -> Episode? {
        return apiService.allEpisodes.first { $0._id == episodeId }
    }
    
    private func getFeaturedShowColors() -> [Color] {
        return [
            Color(red: 0.2, green: 0.6, blue: 1.0),   // Blue
            Color(red: 0.8, green: 0.4, blue: 0.2),   // Orange
            Color(red: 0.3, green: 0.7, blue: 0.4),   // Green
            Color(red: 0.6, green: 0.2, blue: 0.8),   // Purple
            Color(red: 1.0, green: 0.7, blue: 0.3),   // Yellow
            Color(red: 0.9, green: 0.3, blue: 0.9)    // Pink
        ]
    }
    
    // Helper function to convert Episode to VideoData for backward compatibility
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
    let color: Color
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            // Featured badge
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.yellow)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 24, height: 24)
                                        )
                                        .padding(8)
                                }
                                Spacer()
                            }
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: show.showCategory.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("\(show.episodeCount)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("episodes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                
                VStack(spacing: 8) {
                    Text(show.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 160)
                    
                    Text(show.showCategory.rawValue)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(width: 160)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

// MARK: - Enhanced Live Stream Card with Fixed Streaming
struct EnhancedLiveStreamCard: View {
    let stream: LiveStream
    let number: String
    let subtitle: String
    let imageName: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isLivePulsing = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 25) {
                ZStack {
                    // Custom background image for each live stream
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 440, height: 248)
                        .clipped()
                        .overlay(
                            // Dark overlay for text readability
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                    
                    // Content overlay
                    VStack(spacing: 16) {
                        Text("GREATER LOVE TV")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2, x: 1, y: 1)
                        
                        Text(number)
                            .font(.system(size: 96, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(stream.broadcasting_status == "online" ? Color.red : Color.gray)
                                .frame(width: 12, height: 12)
                                .scaleEffect(stream.broadcasting_status == "online" && isLivePulsing ? 1.3 : 1.0)
                            
                            Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.8), radius: 1, x: 1, y: 1)
                        }
                    }
                    
                    // Enhanced play icon overlay for immediate playback indication
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.9))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(isFocused ? 1.1 : 1.0)
                                
                                Text("WATCH LIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.9))
                                    .cornerRadius(6)
                            }
                            .padding(16)
                        }
                    }
                    
                    // Focus indicator
                    if isFocused {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 440, height: 248)
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(
                    color: isFocused ? .white.opacity(0.4) : .black.opacity(0.3),
                    radius: isFocused ? 12 : 6,
                    x: 0,
                    y: isFocused ? 8 : 4
                )
                
                VStack(spacing: 8) {
                    Text(subtitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(stream.name)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // Additional live indicator
                        if stream.broadcasting_status == "online" {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                
                                Text("LIVE")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
        .onAppear {
            isLivePulsing = true
        }
    }
}
