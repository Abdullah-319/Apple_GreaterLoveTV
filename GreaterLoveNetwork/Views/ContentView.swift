import SwiftUI

// MARK: - Content View with Enhanced Navigation and Fixed Player Issues
struct ContentView: View {
    @StateObject private var apiService = CastrAPIService()
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedNavItem = "HOME"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.6)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    NavigationBarWithProperFocus(selectedItem: $selectedNavItem)
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Group {
                                switch selectedNavItem {
                                case "HOME":
                                    HomeViewWithProperNavigation()
                                        .environmentObject(apiService)
                                        .environmentObject(progressManager)
                                        .id("HOME_TOP")
                                case "ABOUT US":
                                    AboutViewWithProperNavigation()
                                        .id("ABOUT_TOP")
                                case "ALL SHOWS":
                                    ShowsViewWithProperNavigation()
                                        .environmentObject(apiService)
                                        .environmentObject(progressManager)
                                        .id("SHOWS_TOP")
                                case "INFO":
                                    QRCodesView()
                                        .id("INFO_TOP")
                                default:
                                    HomeViewWithProperNavigation()
                                        .environmentObject(apiService)
                                        .environmentObject(progressManager)
                                        .id("DEFAULT_TOP")
                                }
                            }
                        }
                        .onChange(of: selectedNavItem) { newValue in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                switch newValue {
                                case "HOME":
                                    proxy.scrollTo("HOME_TOP", anchor: .top)
                                case "ABOUT US":
                                    proxy.scrollTo("ABOUT_TOP", anchor: .top)
                                case "ALL SHOWS":
                                    proxy.scrollTo("SHOWS_TOP", anchor: .top)
                                case "INFO":
                                    proxy.scrollTo("INFO_TOP", anchor: .top)
                                default:
                                    proxy.scrollTo("DEFAULT_TOP", anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            apiService.fetchAllContent()
        }
    }
}

// MARK: - Navigation Bar with Proper Focus Management
struct NavigationBarWithProperFocus: View {
    @Binding var selectedItem: String
    
    private let navItems = ["HOME", "ABOUT US", "ALL SHOWS", "INFO"]
    @FocusState private var focusedItem: String?
    @State private var shouldMaintainFocus = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image("tvos_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.leading, 60)
            
            Spacer()
            
            HStack(spacing: 80) {
                ForEach(navItems, id: \.self) { item in
                    NavigationBarButton(
                        title: item,
                        isSelected: selectedItem == item,
                        isFocused: focusedItem == item
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedItem = item
                            shouldMaintainFocus = true
                        }
                    }
                    .focused($focusedItem, equals: item)
                }
            }
            .padding(.trailing, 60)
            
            Spacer()
        }
        .padding(.vertical, 25)
        .background(Color.black.opacity(0.95))
        .zIndex(1)
        .onChange(of: focusedItem) { newFocusedItem in
            if let newItem = newFocusedItem, newItem != selectedItem && !shouldMaintainFocus {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedItem = newItem
                }
            }
            shouldMaintainFocus = false
        }
        .onAppear {
            if focusedItem == nil {
                focusedItem = selectedItem
            }
        }
    }
}

// MARK: - Home View with Fixed Live Streaming Navigation
struct HomeViewWithProperNavigation: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    @State private var selectedShow: Show?
    @State private var showingShowDetail = false
    @State private var selectedLiveStream: LiveStream?
    @State private var showingLivePlayer = false
    
    // Focus states for proper navigation flow - matching UI hierarchy
    @FocusState private var smartCTAFocused: Bool
    @FocusState private var continueWatchingFocused: Int?
    @FocusState private var liveStreamsFocused: Int?
    @FocusState private var featuredShowsFocused: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            ScrollView {
                VStack(spacing: 80) {
                    if !progressManager.getContinueWatchingVideos().isEmpty {
                        continueWatchingSection
                    }
                    
                    liveStreamsSection
                    
                    featuredShowsSection
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 100)
            }
            .background(Color.black.opacity(0.8))
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
        .focusable()
        .onMoveCommand { direction in
            if direction == .down {
                smartCTAFocused = true
            }
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
                if !progressManager.getContinueWatchingVideos().isEmpty {
                    continueWatchingFocused = 0
                } else {
                    liveStreamsFocused = 0
                }
            case .up:
                smartCTAFocused = false
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
                        LiveStreamCard(
                            stream: stream,
                            number: "\(index + 1)",
                            subtitle: "Greater Love TV \(index == 0 ? "I" : "II")",
                            imageName: index == 0 ? "GL_live_1" : "GL_live_2"
                        ) {
                            selectedLiveStream = stream
                            showingLivePlayer = true
                        }
                        .focused($liveStreamsFocused, equals: index)
                        .onMoveCommand { direction in
                            switch direction {
                            case .up:
                                liveStreamsFocused = nil
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
                                if index < 1 {
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
                            LoadingShowCard(color: getLoadingColors()[index])
                        }
                    } else {
                        let featuredShows = Array(apiService.getFeaturedShows().enumerated())
                        
                        ForEach(featuredShows, id: \.element.id) { index, show in
                            let colors: [Color] = getShowColors()
                            ShowInfoCard(
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
                                case .down:
                                    break
                                case .left:
                                    if index > 0 {
                                        featuredShowsFocused = index - 1
                                    }
                                case .right:
                                    if index < featuredShows.count - 1 {
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
    
    private func getLoadingColors() -> [Color] {
        return [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan]
    }
    
    private func getShowColors() -> [Color] {
        return [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan]
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

// MARK: - About View Wrapper with Proper Navigation
struct AboutViewWithProperNavigation: View {
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        AboutView()
            .focused($isContentFocused)
            .focusable()
            .onMoveCommand { direction in
                if direction == .down {
                    isContentFocused = true
                }
            }
    }
}

// MARK: - Shows View Wrapper with Proper Navigation
struct ShowsViewWithProperNavigation: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        ShowsView()
            .environmentObject(apiService)
            .environmentObject(progressManager)
            .focused($isContentFocused)
            .focusable()
            .onMoveCommand { direction in
                if direction == .down {
                    isContentFocused = true
                }
            }
    }
}

// MARK: - Show Info Card
struct ShowInfoCard: View {
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
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 8) {
                        Image(systemName: show.showCategory.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("\(show.episodeCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("episodes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                
                VStack(spacing: 8) {
                    Text(show.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                    
                    Text(show.showCategory.rawValue)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(width: 140)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
