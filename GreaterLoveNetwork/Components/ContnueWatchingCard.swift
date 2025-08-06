import SwiftUI

// MARK: - Continue Watching Card
struct ContinueWatchingCard: View {
    let videoData: VideoData
    let watchProgress: WatchProgress
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                ZStack {
                    // Video thumbnail or placeholder
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
                    
                    // Progress bar overlay at bottom
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // Progress bar background
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 8)
                            
                            // Progress bar fill
                            GeometryReader { geo in
                                HStack {
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: geo.size.width * CGFloat(watchProgress.progressPercentage / 100))
                                    
                                    Spacer()
                                }
                            }
                            .frame(height: 4)
                            .background(Color.white.opacity(0.3))
                        }
                    }
                    
                    // Continue watching overlay
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
                                
                                Text("Continue")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(4)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                            }
                            .padding(8)
                        }
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(color: isFocused ? .blue.opacity(0.5) : .clear, radius: 8)
                
                // Video info and progress
                VStack(spacing: 8) {
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.custom("Poppins-Medium", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                    
                    HStack(spacing: 8) {
                        Text(watchProgress.formattedCurrentTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("\(Int(watchProgress.progressPercentage))% watched")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("•")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(watchProgress.formattedRemainingTime + " left")
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
