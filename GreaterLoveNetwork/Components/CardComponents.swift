import SwiftUI

// MARK: - Card Components
struct VideoDataCard: View {
    let videoData: VideoData
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @FocusState private var isFocused: Bool
    
    private var watchProgress: WatchProgress? {
        progressManager.getProgress(for: videoData._id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    Group {
                        switch apiService.thumbnailStates[videoData._id] {
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
                                            Color.blue.opacity(0.7),
                                            Color.purple.opacity(0.5)
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
                                        
                                        if let duration = videoData.mediaInfo?.durationMins {
                                            Text("\(duration) min")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                )
                        }
                    }
                    .cornerRadius(12)
                    
                    // Progress bar overlay if video has been watched
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
                .shadow(color: isFocused ? .blue.opacity(0.5) : .clear, radius: 8)
                
                // Video title and progress info
                VStack(spacing: 8) {
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                    
                    if let progress = watchProgress {
                        HStack(spacing: 8) {
                            Text("\(Int(progress.progressPercentage))% watched")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("•")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("\(progress.formattedRemainingTime) left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    } else if let duration = videoData.mediaInfo?.durationMins {
                        Text("\(duration) min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .onAppear {
            if apiService.thumbnailStates[videoData._id] == nil {
                apiService.loadThumbnail(for: videoData)
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: {}) {
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
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("\(category.videos.count) videos")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                    .cornerRadius(8)
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}


struct ShowCircleCard: View {
    let videoData: VideoData
    let color: Color
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @StateObject private var progressManager = WatchProgressManager.shared
    @FocusState private var isFocused: Bool
    
    private var watchProgress: WatchProgress? {
        progressManager.getProgress(for: videoData._id)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                ZStack {
                    Group {
                        switch apiService.thumbnailStates[videoData._id] {
                        case .loading:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                )
                        case .loaded(let image):
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                        case .failed, .none:
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Text(String(videoData.fileName.prefix(2).uppercased()))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                    
                    // Progress indicator for circular cards
                    if let progress = watchProgress {
                        Circle()
                            .stroke(Color.orange, lineWidth: 4)
                            .frame(width: 144, height: 144)
                            .overlay(
                                Circle()
                                    .trim(from: 0, to: CGFloat(progress.progressPercentage / 100))
                                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 144, height: 144)
                            )
                    }
                }
                
                VStack(spacing: 8) {
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                    
                    if let progress = watchProgress {
                        Text("\(Int(progress.progressPercentage))% watched")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    } else if let duration = videoData.mediaInfo?.durationMins {
                        Text("\(duration) min")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .frame(width: 140)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
        .onAppear {
            if apiService.thumbnailStates[videoData._id] == nil {
                apiService.loadThumbnail(for: videoData)
            }
        }
    }
}

struct LiveStreamCard: View {
    let stream: LiveStream
    let number: String
    let subtitle: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 25) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.8),
                                Color(red: 0.1, green: 0.3, blue: 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 440, height: 248)
                    .overlay(
                        VStack(spacing: 10) {
                            Text("GREATER LOVE TV")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(number)
                                .font(.system(size: 96, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stream.broadcasting_status == "online" ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .cornerRadius(12)
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
                VStack(spacing: 5) {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(stream.name)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
