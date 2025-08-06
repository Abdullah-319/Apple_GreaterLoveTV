import SwiftUI

// MARK: - Categories View with Continue Watching
struct CategoriesView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 80) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 60) {
                Text("ALL CATEGORIES")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                
                // Continue Watching Section (if any)
                if !progressManager.getContinueWatchingVideos().isEmpty {
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
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 80)
                        
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
                            .padding(.horizontal, 80)
                        }
                    }
                }
                
                // Categories Grid
                if apiService.isLoading || apiService.categories.isEmpty {
                    VStack(spacing: 50) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 50) {
                                ForEach(0..<4, id: \.self) { _ in
                                    LoadingCategoryCard()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50)
                    ], spacing: 50) {
                        ForEach(apiService.categories) { category in
                            CategoryDetailCard(category: category) {
                                // Show first video in category
                                if let firstVideo = category.videos.first {
                                    selectedContent = firstVideo
                                    showingVideoPlayer = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
        .background(Color.black.opacity(0.8))
        .sheet(isPresented: $showingVideoPlayer) {
            if let stream = selectedContent as? LiveStream {
                LiveTVPlayerView(stream: stream)
            } else if let videoData = selectedContent as? VideoData {
                VideoDataPlayerView(videoData: videoData)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findVideoData(by videoId: String) -> VideoData? {
        return apiService.videoData.first { $0._id == videoId }
    }
}

// MARK: - Updated Category Detail Card with Click Action
struct CategoryDetailCard: View {
    let category: Category
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 158)
                    .overlay(
                        VStack {
                            Text(category.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(category.videos.count) videos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )
                    .cornerRadius(8)
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
