//import SwiftUI
//import Foundation
//
//// MARK: - Enhanced Category System
//extension CastrAPIService {
//    
//    private func createEnhancedCategories(from videoData: [VideoData]) -> [Category] {
//        let allVideos = videoData
//        var categories: [Category] = []
//        
//        // 1. All Videos Category
//        categories.append(Category(
//            name: "All Videos",
//            image: "all_videos",
//            color: Color(red: 0.2, green: 0.6, blue: 1.0),
//            videos: allVideos
//        ))
//        
//        // 2. Continue Watching (will be populated by WatchProgressManager)
//        let continueWatchingVideos = getContinueWatchingVideos(from: allVideos)
//        if !continueWatchingVideos.isEmpty {
//            categories.append(Category(
//                name: "Continue Watching",
//                image: "continue_watching",
//                color: Color.orange,
//                videos: continueWatchingVideos
//            ))
//        }
//        
//        // 3. Recent Uploads (Last 30 days)
//        let recentVideos = getRecentVideos(from: allVideos, days: 30)
//        categories.append(Category(
//            name: "Recently Added",
//            image: "recent_videos",
//            color: Color(red: 0.9, green: 0.3, blue: 0.9),
//            videos: recentVideos
//        ))
//        
//        // 4. Ministries & Churches
//        let ministryVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("ministries") ||
//                   fileName.contains("church") ||
//                   fileName.contains("ct townsend") ||
//                   fileName.contains("sandra hancock") ||
//                   fileName.contains("ignited church") ||
//                   fileName.contains("grace pointe") ||
//                   fileName.contains("united christian") ||
//                   fileName.contains("evangelistic") ||
//                   fileName.contains("higher praise")
//        }
//        categories.append(Category(
//            name: "Ministries & Churches",
//            image: "ministries",
//            color: Color(red: 0.3, green: 0.7, blue: 0.4),
//            videos: ministryVideos
//        ))
//        
//        // 5. Teaching & Truth Series
//        let teachingVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("truth") ||
//                   fileName.contains("matters") ||
//                   fileName.contains("teaching") ||
//                   fileName.contains("biblical") ||
//                   fileName.contains("study") ||
//                   fileName.contains("lesson")
//        }
//        categories.append(Category(
//            name: "Biblical Teaching",
//            image: "teaching",
//            color: Color(red: 0.8, green: 0.4, blue: 0.2),
//            videos: teachingVideos
//        ))
//        
//        // 6. Inspirational & Testimony
//        let inspirationalVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("testimony") ||
//                   fileName.contains("hope") ||
//                   fileName.contains("inspiration") ||
//                   fileName.contains("voice of hope") ||
//                   fileName.contains("fresh oil") ||
//                   fileName.contains("second chances") ||
//                   fileName.contains("emily testimony") ||
//                   fileName.contains("prophecy") ||
//                   fileName.contains("promise")
//        }
//        categories.append(Category(
//            name: "Inspirational & Testimony",
//            image: "inspirational",
//            color: Color(red: 1.0, green: 0.7, blue: 0.3),
//            videos: inspirationalVideos
//        ))
//        
//        // 7. Live Streams & Events
//        let liveVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("live") ||
//                   fileName.contains("stream") ||
//                   fileName.contains("event") ||
//                   fileName.contains("broadcast")
//        }
//        categories.append(Category(
//            name: "Live Events",
//            image: "live_events",
//            color: Color.red,
//            videos: liveVideos
//        ))
//        
//        // 8. Biblical Studies (Books of the Bible)
//        let biblicalStudyVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("daniel") ||
//                   fileName.contains("acts") ||
//                   fileName.contains("psalms") ||
//                   fileName.contains("john") ||
//                   fileName.contains("matthew") ||
//                   fileName.contains("romans") ||
//                   fileName.contains("genesis") ||
//                   fileName.contains("revelation")
//        }
//        categories.append(Category(
//            name: "Biblical Studies",
//            image: "biblical_studies",
//            color: Color(red: 0.4, green: 0.3, blue: 0.8),
//            videos: biblicalStudyVideos
//        ))
//        
//        // 9. Faith & Worship
//        let faithVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("faith") ||
//                   fileName.contains("worship") ||
//                   fileName.contains("praise") ||
//                   fileName.contains("prayer") ||
//                   fileName.contains("refuge") ||
//                   fileName.contains("closer") ||
//                   fileName.contains("awaken")
//        }
//        categories.append(Category(
//            name: "Faith & Worship",
//            image: "faith_worship",
//            color: Color(red: 0.6, green: 0.2, blue: 0.8),
//            videos: faithVideos
//        ))
//        
//        // 10. Series & Shows
//        let seriesVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("ep") ||
//                   fileName.contains("episode") ||
//                   fileName.contains("part") ||
//                   fileName.contains("pt") ||
//                   fileName.contains("series") ||
//                   fileName.contains("show")
//        }
//        categories.append(Category(
//            name: "Series & Shows",
//            image: "series_shows",
//            color: Color(red: 0.2, green: 0.8, blue: 0.8),
//            videos: seriesVideos
//        ))
//        
//        // Filter out empty categories (except "All Videos")
//        return categories.filter { $0.name == "All Videos" || !$0.videos.isEmpty }
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func getContinueWatchingVideos(from videos: [VideoData]) -> [VideoData] {
//        let progressManager = WatchProgressManager.shared
//        let continueWatchingIds = Set(progressManager.getContinueWatchingVideos().map { $0.videoId })
//        return videos.filter { continueWatchingIds.contains($0._id) }
//    }
//    
//    private func getRecentVideos(from videos: [VideoData], days: Int) -> [VideoData] {
//        let calendar = Calendar.current
//        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
//        
//        let dateFormatter = ISO8601DateFormatter()
//        
//        return videos.filter { video in
//            guard let date = dateFormatter.date(from: video.creationTime) else { return false }
//            return date > cutoffDate
//        }.sorted { video1, video2 in
//            let date1 = dateFormatter.date(from: video1.creationTime) ?? Date.distantPast
//            let date2 = dateFormatter.date(from: video2.creationTime) ?? Date.distantPast
//            return date1 > date2
//        }
//    }
//    
//    // Update the existing createCategories method to use the enhanced system
//    func createCategories(from videoData: [VideoData]) {
//        self.categories = createEnhancedCategories(from: videoData)
//    }
//}
//
//// MARK: - Updated CastrAPIService Extension
//extension CastrAPIService {
//    
//    // Replace the existing createCategories method in your CastrAPIService.swift with this enhanced version
//    func createEnhancedCategories(from videoData: [VideoData]) {
//        let allVideos = videoData
//        var categories: [Category] = []
//        
//        // 1. All Videos Category
//        categories.append(Category(
//            name: "All Videos",
//            image: "all_videos",
//            color: Color(red: 0.2, green: 0.6, blue: 1.0),
//            videos: allVideos
//        ))
//        
//        // 2. Recent Uploads (Last 30 days)
//        let recentVideos = getRecentVideos(from: allVideos, days: 30)
//        categories.append(Category(
//            name: "Recently Added",
//            image: "recent_videos",
//            color: Color(red: 0.9, green: 0.3, blue: 0.9),
//            videos: recentVideos
//        ))
//        
//        // 3. Ministries & Churches
//        let ministryVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("ministries") ||
//                   fileName.contains("church") ||
//                   fileName.contains("ct townsend") ||
//                   fileName.contains("sandra hancock") ||
//                   fileName.contains("ignited church") ||
//                   fileName.contains("grace pointe") ||
//                   fileName.contains("united christian") ||
//                   fileName.contains("evangelistic") ||
//                   fileName.contains("higher praise")
//        }
//        if !ministryVideos.isEmpty {
//            categories.append(Category(
//                name: "Ministries & Churches",
//                image: "ministries",
//                color: Color(red: 0.3, green: 0.7, blue: 0.4),
//                videos: ministryVideos
//            ))
//        }
//        
//        // 4. Teaching & Truth Series
//        let teachingVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("truth") ||
//                   fileName.contains("matters") ||
//                   fileName.contains("teaching") ||
//                   fileName.contains("biblical") ||
//                   fileName.contains("study") ||
//                   fileName.contains("lesson")
//        }
//        if !teachingVideos.isEmpty {
//            categories.append(Category(
//                name: "Biblical Teaching",
//                image: "teaching",
//                color: Color(red: 0.8, green: 0.4, blue: 0.2),
//                videos: teachingVideos
//            ))
//        }
//        
//        // 5. Inspirational & Testimony
//        let inspirationalVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("testimony") ||
//                   fileName.contains("hope") ||
//                   fileName.contains("inspiration") ||
//                   fileName.contains("voice of hope") ||
//                   fileName.contains("fresh oil") ||
//                   fileName.contains("second chances") ||
//                   fileName.contains("emily testimony") ||
//                   fileName.contains("prophecy") ||
//                   fileName.contains("promise")
//        }
//        if !inspirationalVideos.isEmpty {
//            categories.append(Category(
//                name: "Inspirational & Testimony",
//                image: "inspirational",
//                color: Color(red: 1.0, green: 0.7, blue: 0.3),
//                videos: inspirationalVideos
//            ))
//        }
//        
//        // 6. Biblical Studies (Books of the Bible)
//        let biblicalStudyVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("daniel") ||
//                   fileName.contains("acts") ||
//                   fileName.contains("psalms") ||
//                   fileName.contains("john") ||
//                   fileName.contains("matthew") ||
//                   fileName.contains("romans") ||
//                   fileName.contains("genesis") ||
//                   fileName.contains("revelation")
//        }
//        if !biblicalStudyVideos.isEmpty {
//            categories.append(Category(
//                name: "Biblical Studies",
//                image: "biblical_studies",
//                color: Color(red: 0.4, green: 0.3, blue: 0.8),
//                videos: biblicalStudyVideos
//            ))
//        }
//        
//        // 7. Faith & Worship
//        let faithVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("faith") ||
//                   fileName.contains("worship") ||
//                   fileName.contains("praise") ||
//                   fileName.contains("prayer") ||
//                   fileName.contains("refuge") ||
//                   fileName.contains("closer") ||
//                   fileName.contains("awaken")
//        }
//        if !faithVideos.isEmpty {
//            categories.append(Category(
//                name: "Faith & Worship",
//                image: "faith_worship",
//                color: Color(red: 0.6, green: 0.2, blue: 0.8),
//                videos: faithVideos
//            ))
//        }
//        
//        // 8. Series & Shows
//        let seriesVideos = allVideos.filter { video in
//            let fileName = video.fileName.lowercased()
//            return fileName.contains("ep") ||
//                   fileName.contains("episode") ||
//                   fileName.contains("part") ||
//                   fileName.contains("pt") ||
//                   fileName.contains("series") ||
//                   fileName.contains("show")
//        }
//        if !seriesVideos.isEmpty {
//            categories.append(Category(
//                name: "Series & Shows",
//                image: "series_shows",
//                color: Color(red: 0.2, green: 0.8, blue: 0.8),
//                videos: seriesVideos
//            ))
//        }
//        
//        self.categories = categories
//    }
//}
//
//// MARK: - Enhanced Category Card with Better Visual Design
//struct EnhancedCategoryCard: View {
//    let category: Category
//    let action: () -> Void
//    @FocusState private var isFocused: Bool
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 20) {
//                ZStack {
//                    // Background with gradient
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    category.color,
//                                    category.color.opacity(0.7),
//                                    category.color.opacity(0.9)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .frame(width: 320, height: 180)
//                    
//                    // Content overlay
//                    VStack(spacing: 12) {
//                        // Category icon or image
//                        getCategoryIcon(for: category.name)
//                            .font(.system(size: 40, weight: .medium))
//                            .foregroundColor(.white)
//                        
//                        // Category title
//                        Text(category.name)
//                            .font(.system(size: 20, weight: .bold))
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        // Video count with styling
//                        HStack(spacing: 6) {
//                            Image(systemName: "play.circle.fill")
//                                .font(.system(size: 14))
//                                .foregroundColor(.white.opacity(0.9))
//                            
//                            Text("\(category.videos.count) videos")
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(.white.opacity(0.9))
//                        }
//                    }
//                    .padding(20)
//                    
//                    // Focus indicator
//                    if isFocused {
//                        RoundedRectangle(cornerRadius: 16)
//                            .stroke(Color.white, lineWidth: 3)
//                            .frame(width: 320, height: 180)
//                    }
//                }
//                .scaleEffect(isFocused ? 1.05 : 1.0)
//                .shadow(color: isFocused ? .white.opacity(0.3) : .black.opacity(0.3), radius: 8)
//            }
//        }
//        .buttonStyle(PlainButtonStyle())
//        .focused($isFocused)
//        .animation(.easeInOut(duration: 0.2), value: isFocused)
//    }
//    
//    private func getCategoryIcon(for categoryName: String) -> Image {
//        switch categoryName {
//        case "All Videos":
//            return Image(systemName: "square.grid.3x3")
//        case "Continue Watching":
//            return Image(systemName: "clock.arrow.circlepath")
//        case "Recently Added":
//            return Image(systemName: "calendar.badge.plus")
//        case "Ministries & Churches":
//            return Image(systemName: "building.2")
//        case "Biblical Teaching":
//            return Image(systemName: "book")
//        case "Inspirational & Testimony":
//            return Image(systemName: "heart.circle")
//        case "Live Events":
//            return Image(systemName: "dot.radiowaves.left.and.right")
//        case "Biblical Studies":
//            return Image(systemName: "text.book.closed")
//        case "Faith & Worship":
//            return Image(systemName: "hands.sparkles")
//        case "Series & Shows":
//            return Image(systemName: "tv")
//        default:
//            return Image(systemName: "folder")
//        }
//    }
//}
//
//// MARK: - Enhanced Categories View with Better Layout
//struct EnhancedCategoriesView: View {
//    @EnvironmentObject var apiService: CastrAPIService
//    @StateObject private var progressManager = WatchProgressManager.shared
//    @State private var selectedContent: Any?
//    @State private var showingVideoPlayer = false
//    @State private var selectedCategory: Category?
//    @State private var showingCategoryDetail = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Header
//            headerSection
//            
//            // Main content
//            ScrollView {
//                VStack(alignment: .leading, spacing: 80) {
//                    // Continue Watching Section (if any)
//                    if !progressManager.getContinueWatchingVideos().isEmpty {
//                        continueWatchingSection
//                    }
//                    
//                    // Categories Grid
//                    categoriesGridSection
//                }
//                .padding(.horizontal, 60)
//                .padding(.bottom, 100)
//            }
//        }
//        .background(
//            LinearGradient(
//                colors: [
//                    Color.black,
//                    Color.black.opacity(0.9),
//                    Color.black
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//        .sheet(isPresented: $showingVideoPlayer) {
//            if let stream = selectedContent as? LiveStream {
//                LiveTVPlayerView(stream: stream)
//            } else if let videoData = selectedContent as? VideoData {
//                VideoDataPlayerView(videoData: videoData)
//            }
//        }
//        .sheet(isPresented: $showingCategoryDetail) {
//            if let category = selectedCategory {
//                CategoryDetailView(category: category) { videoData in
//                    selectedContent = videoData
//                    showingCategoryDetail = false
//                    showingVideoPlayer = true
//                }
//            }
//        }
//    }
//    
//    private var headerSection: some View {
//        VStack(alignment: .leading, spacing: 30) {
//            Spacer()
//                .frame(height: 60)
//            
//            HStack {
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("EXPLORE")
//                        .font(.system(size: 28, weight: .medium))
//                        .foregroundColor(.white.opacity(0.8))
//                    
//                    Text("ALL CATEGORIES")
//                        .font(.system(size: 48, weight: .bold))
//                        .foregroundColor(.white)
//                        .letterSpacing(-1)
//                }
//                
//                Spacer()
//                
//                // Category count indicator
//                VStack(alignment: .trailing, spacing: 4) {
//                    Text("\(apiService.categories.count)")
//                        .font(.system(size: 36, weight: .bold))
//                        .foregroundColor(.white)
//                    
//                    Text("Categories")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.white.opacity(0.7))
//                }
//                .padding(.horizontal, 25)
//                .padding(.vertical, 15)
//                .background(Color.white.opacity(0.1))
//                .cornerRadius(12)
//            }
//            .padding(.horizontal, 60)
//        }
//        .frame(height: 200)
//        .background(Color.black.opacity(0.95))
//    }
//    
//    private var continueWatchingSection: some View {
//        VStack(alignment: .leading, spacing: 40) {
//            HStack {
//                Image(systemName: "clock.arrow.circlepath")
//                    .font(.system(size: 24))
//                    .foregroundColor(.orange)
//                
//                Text("Continue Watching")
//                    .font(.system(size: 28, weight: .bold))
//                    .foregroundColor(.white)
//                
//                Spacer()
//                
//                Button("Clear All") {
//                    progressManager.clearAllProgress()
//                }
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(.gray)
//                .padding(.horizontal, 20)
//                .padding(.vertical, 8)
//                .background(Color.white.opacity(0.1))
//                .cornerRadius(8)
//            }
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 30) {
//                    ForEach(progressManager.getContinueWatchingVideos()) { progress in
//                        if let videoData = findVideoData(by: progress.videoId) {
//                            ContinueWatchingCard(
//                                videoData: videoData,
//                                watchProgress: progress
//                            ) {
//                                selectedContent = videoData
//                                showingVideoPlayer = true
//                            }
//                            .environmentObject(apiService)
//                        }
//                    }
//                }
//                .padding(.horizontal, 40)
//            }
//        }
//    }
//    
//    private var categoriesGridSection: some View {
//        VStack(alignment: .leading, spacing: 50) {
//            HStack {
//                Image(systemName: "square.grid.3x3")
//                    .font(.system(size: 24))
//                    .foregroundColor(.blue)
//                
//                Text("Browse Categories")
//                    .font(.system(size: 28, weight: .bold))
//                    .foregroundColor(.white)
//                
//                Spacer()
//            }
//            
//            if apiService.isLoading || apiService.categories.isEmpty {
//                // Loading state
//                LazyVGrid(columns: [
//                    GridItem(.flexible(), spacing: 40),
//                    GridItem(.flexible(), spacing: 40),
//                    GridItem(.flexible(), spacing: 40)
//                ], spacing: 40) {
//                    ForEach(0..<9, id: \.self) { _ in
//                        LoadingCategoryCard()
//                    }
//                }
//            } else {
//                // Categories grid
//                LazyVGrid(columns: [
//                    GridItem(.flexible(), spacing: 40),
//                    GridItem(.flexible(), spacing: 40),
//                    GridItem(.flexible(), spacing: 40)
//                ], spacing: 40) {
//                    ForEach(apiService.categories) { category in
//                        EnhancedCategoryCard(category: category) {
//                            selectedCategory = category
//                            showingCategoryDetail = true
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func findVideoData(by videoId: String) -> VideoData? {
//        return apiService.videoData.first { $0._id == videoId }
//    }
//}
//
//// MARK: - Category Detail View
//struct CategoryDetailView: View {
//    let category: Category
//    let onVideoSelect: (VideoData) -> Void
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            // Header
//            VStack(alignment: .leading, spacing: 20) {
//                HStack {
//                    Button("Back") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                    .font(.system(size: 16, weight: .semibold))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 10)
//                    .background(Color.white.opacity(0.2))
//                    .cornerRadius(8)
//                    
//                    Spacer()
//                }
//                
//                HStack {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Text(category.name)
//                            .font(.system(size: 36, weight: .bold))
//                            .foregroundColor(.white)
//                        
//                        Text("\(category.videos.count) videos available")
//                            .font(.system(size: 18, weight: .medium))
//                            .foregroundColor(.white.opacity(0.8))
//                    }
//                    
//                    Spacer()
//                }
//            }
//            .padding(.horizontal, 60)
//            .padding(.vertical, 40)
//            .background(category.color.opacity(0.8))
//            
//            // Videos grid
//            ScrollView {
//                LazyVGrid(columns: [
//                    GridItem(.flexible(), spacing: 30),
//                    GridItem(.flexible(), spacing: 30),
//                    GridItem(.flexible(), spacing: 30),
//                    GridItem(.flexible(), spacing: 30)
//                ], spacing: 40) {
//                    ForEach(category.videos) { video in
//                        VideoDataCard(videoData: video) {
//                            onVideoSelect(video)
//                        }
//                    }
//                }
//                .padding(.horizontal, 60)
//                .padding(.vertical, 40)
//            }
//        }
//        .background(Color.black)
//    }
//}
