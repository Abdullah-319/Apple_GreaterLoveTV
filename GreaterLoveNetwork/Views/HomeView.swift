import SwiftUI

// MARK: - Home View with Continue Watching
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
            VStack(spacing: 80) {
                // Show continue watching section only if there are videos in progress
                if !progressManager.getContinueWatchingVideos().isEmpty {
                    continueWatchingSection
                }
                
                recentVideosSection
                categoriesSection
                showsSection
                liveStreamsSection
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 100)
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
                        
                        CTAButton(title: progressManager.getContinueWatchingVideos().isEmpty ? "Start Watching" : "Continue Watching") {
                            // Scroll to continue watching section or start browsing
                            withAnimation(.easeInOut(duration: 0.5)) {
                                if let firstVideo = progressManager.getContinueWatchingVideos().first,
                                   let videoData = findVideoData(by: firstVideo.videoId) {
                                    selectedContent = videoData
                                    showingVideoPlayer = true
                                }
                            }
                        }
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
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                Text("Continue Watching")
                    .font(.custom("Poppins-Medium", size: 24))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Clear All") {
                    progressManager.clearAllProgress()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
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
                Text(progressManager.getContinueWatchingVideos().isEmpty ? "Recent Videos" : "More Videos")
                    .font(.custom("Poppins-Medium", size: 24))
                    .foregroundColor(.white)
                Spacer()
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
                        let filteredVideos = apiService.videoData.filter { !continueWatchingIds.contains($0._id) }
                        
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
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Categories")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.categories.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCategoryCard()
                        }
                    } else {
                        ForEach(apiService.categories) { category in
                            CategoryCard(category: category)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var showsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Shows")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 50) {
                    if apiService.isLoading || apiService.videoData.isEmpty {
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan][index])
                        }
                    } else {
                        ForEach(Array(apiService.videoData.prefix(6).enumerated()), id: \.element.id) { index, videoData in
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
            Text("Live Streams Show")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            HStack(spacing: 60) {
                if apiService.isLoading || apiService.liveStreams.isEmpty {
                    LoadingLiveStreamCard(number: "1", subtitle: "Greater Love Tv I")
                    LoadingLiveStreamCard(number: "2", subtitle: "Greater Love Tv II")
                } else {
                    ForEach(Array(apiService.liveStreams.prefix(2).enumerated()), id: \.element.id) { index, stream in
                        LiveStreamCard(
                            stream: stream,
                            number: "\(index + 1)",
                            subtitle: "Greater Love Tv \(index == 0 ? "I" : "II")"
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
}
