import SwiftUI

// MARK: - Enhanced Home View with Smart Categorization
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            ScrollView {
                VStack(spacing: 80) {
                    // Show continue watching section only if there are videos in progress
                    if !progressManager.getContinueWatchingVideos().isEmpty {
                        continueWatchingSection
                    }
                    
                    // Recently Added Videos
                    recentVideosSection
                    
                    // Featured Categories (Top 5 most populated categories)
                    featuredCategoriesSection
                    
                    // Quick Access Categories
                    quickAccessSection
                    
                    // Shows & Series
                    showsSection
                    
                    // Live Streams
                    liveStreamsSection
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 100)
            }
            .background(Color.black.opacity(0.8))
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let stream = selectedContent as? LiveStream {
                LiveTVPlayerView(stream: stream)
            } else if let videoData = selectedContent as? VideoData {
                VideoDataPlayerView(videoData: videoData)
            }
        }
        .onAppear {
            // Refresh progress manager when view appears
            progressManager.objectWillChange.send()
        }
    }
    
    private func headerSection() -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STREAM YOUR")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("FAVORITE")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("BIBLE TEACHERS")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
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
        
        return CTAButton(title: buttonTitle) {
            withAnimation(.easeInOut(duration: 0.5)) {
                if hasWatchHistory,
                   let firstVideo = progressManager.getContinueWatchingVideos().first,
                   let videoData = findVideoData(by: firstVideo.videoId) {
                    selectedContent = videoData
                    showingVideoPlayer = true
                } else if let recentVideo = apiService.videoData.first {
                    selectedContent = recentVideo
                    showingVideoPlayer = true
                }
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
    
    private var recentVideosSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                    
                    Text(progressManager.getContinueWatchingVideos().isEmpty ? "Recent Videos" : "More Recent Videos")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Latest uploads")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.videoData.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCard()
                        }
                    } else {
                        // Filter out videos that are already in continue watching
                        let continueWatchingIds = Set(progressManager.getContinueWatchingVideos().map { $0.videoId })
                        let filteredVideos = getRecentVideos().filter { !continueWatchingIds.contains($0._id) }
                        
                        ForEach(Array(filteredVideos.prefix(10))) { videoData in
                            VideoDataCard(videoData: videoData) {
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
    
    private var featuredCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Text("Featured Categories")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Most popular content")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.categories.isEmpty {
                        ForEach(0..<4, id: \.self) { index in
                            EnhancedLoadingCategoryCard(index: index)
                        }
                    } else {
                        // Show top 5 categories with most videos
                        let featuredCategories = apiService.categories
                            .filter { $0.name != "All Videos" }
                            .sorted { $0.videos.count > $1.videos.count }
                            .prefix(5)
                        
                        ForEach(Array(featuredCategories)) { category in
                            CompactCategoryCard(category: category) {
                                // Navigate to category or show first video
                                if let firstVideo = category.videos.first {
                                    selectedContent = firstVideo
                                    showingVideoPlayer = true
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Quick Access")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Jump right in")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Quick access buttons for specific categories
            HStack(spacing: 20) {
                QuickAccessButton(
                    title: "Biblical Teaching",
                    icon: "book.circle.fill",
                    color: .orange,
                    action: {
                        if let teachingCategory = apiService.categories.first(where: { $0.name == "Biblical Teaching" }),
                           let firstVideo = teachingCategory.videos.first {
                            selectedContent = firstVideo
                            showingVideoPlayer = true
                        }
                    }
                )
                
                QuickAccessButton(
                    title: "Testimonies",
                    icon: "heart.circle.fill",
                    color: .pink,
                    action: {
                        if let testimonyCategory = apiService.categories.first(where: { $0.name == "Inspirational & Testimony" }),
                           let firstVideo = testimonyCategory.videos.first {
                            selectedContent = firstVideo
                            showingVideoPlayer = true
                        }
                    }
                )
                
                QuickAccessButton(
                    title: "Worship",
                    icon: "hands.sparkles",
                    color: .purple,
                    action: {
                        if let worshipCategory = apiService.categories.first(where: { $0.name == "Faith & Worship" }),
                           let firstVideo = worshipCategory.videos.first {
                            selectedContent = firstVideo
                            showingVideoPlayer = true
                        }
                    }
                )
                
                Spacer()
            }
        }
    }
    
    private var showsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "tv.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.cyan)
                    
                    Text("Shows & Series")
                        .font(.custom("Poppins-Medium", size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Episode-based content")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 50) {
                    if apiService.isLoading || apiService.videoData.isEmpty {
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan][index])
                        }
                    } else {
                        // Prioritize series and episodic content
                        let seriesVideos = apiService.videoData.filter { video in
                            let fileName = video.fileName.lowercased()
                            return fileName.contains("ep") || fileName.contains("part") || fileName.contains("series")
                        }
                        
                        let videosToShow = seriesVideos.isEmpty ? Array(apiService.videoData.prefix(6)) : Array(seriesVideos.prefix(6))
                        
                        ForEach(Array(videosToShow.enumerated()), id: \.element.id) { index, videoData in
                            let colors: [Color] = [.blue, .purple, .green, .orange, .red, .cyan]
                            ShowCircleCard(
                                videoData: videoData,
                                color: colors[index % colors.count]
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
                            subtitle: "Greater Love TV \(index == 0 ? "I" : "II")"
                        ) {
                            selectedContent = stream
                            showingVideoPlayer = true
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func findVideoData(by videoId: String) -> VideoData? {
        return apiService.videoData.first { $0._id == videoId }
    }
    
    private func getRecentVideos() -> [VideoData] {
        // Sort videos by creation time (most recent first)
        return apiService.videoData.sorted { video1, video2 in
            let dateFormatter = ISO8601DateFormatter()
            let date1 = dateFormatter.date(from: video1.creationTime) ?? Date.distantPast
            let date2 = dateFormatter.date(from: video2.creationTime) ?? Date.distantPast
            return date1 > date2
        }
    }
}

// MARK: - Compact Category Card for Home View
struct CompactCategoryCard: View {
    let category: Category
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 160)
                    
                    VStack(spacing: 12) {
                        getCategoryIcon(for: category.name)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(category.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text("\(category.videos.count) videos")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(20)
                    
                    if isFocused {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 280, height: 160)
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(color: isFocused ? .white.opacity(0.3) : .black.opacity(0.2), radius: 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private func getCategoryIcon(for categoryName: String) -> Image {
        switch categoryName {
        case "Biblical Teaching":
            return Image(systemName: "book.closed")
        case "Inspirational & Testimony":
            return Image(systemName: "heart.circle.fill")
        case "Ministries & Churches":
            return Image(systemName: "building.2.crop.circle")
        case "Faith & Worship":
            return Image(systemName: "hands.sparkles.fill")
        case "Biblical Studies":
            return Image(systemName: "text.book.closed")
        case "Series & Shows":
            return Image(systemName: "tv.circle")
        default:
            return Image(systemName: "folder.circle")
        }
    }
}

// MARK: - Quick Access Button
struct QuickAccessButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? color.opacity(0.4) : .black.opacity(0.2), radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Enhanced Live Stream Card
struct EnhancedLiveStreamCard: View {
    let stream: LiveStream
    let number: String
    let subtitle: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isLivePulsing = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 25) {
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.3, blue: 0.7),
                                    Color(red: 0.2, green: 0.4, blue: 0.8),
                                    Color(red: 0.1, green: 0.2, blue: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 440, height: 248)
                        .overlay(
                            // Subtle animated background pattern
                            GeometryReader { geometry in
                                ForEach(0..<20, id: \.self) { index in
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 40, height: 40)
                                        .position(
                                            x: CGFloat.random(in: 0...geometry.size.width),
                                            y: CGFloat.random(in: 0...geometry.size.height)
                                        )
                                        .animation(.linear(duration: Double.random(in: 10...20)).repeatForever(autoreverses: false), value: isLivePulsing)
                                }
                            }
                        )
                        .overlay(
                            VStack(spacing: 16) {
                                Text("GREATER LOVE TV")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                                
                                Text(number)
                                    .font(.system(size: 96, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                                
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(stream.broadcasting_status == "online" ? Color.red : Color.gray)
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(stream.broadcasting_status == "online" && isLivePulsing ? 1.3 : 1.0)
                                    
                                    Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 1, x: 1, y: 1)
                                }
                            }
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
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
                    
                    Text(stream.name)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
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
