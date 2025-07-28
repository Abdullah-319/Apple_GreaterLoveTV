//import SwiftUI
//import AVKit
//
//struct EnhancedVideoPlayer: View {
//    let video: Video
//    @State private var useWebPlayer = true
//    @State private var isLoading = true
//    @State private var hasError = false
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            if hasError {
//                // Error state with manual options
//                VStack(spacing: 20) {
//                    Image(systemName: "exclamationmark.triangle")
//                        .font(.system(size: 60))
//                        .foregroundColor(.orange)
//                    
//                    Text("Unable to load video player")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.white)
//                    
//                    Text("Try opening in browser or use alternative player")
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                        .multilineTextAlignment(.center)
//                    
//                    HStack(spacing: 20) {
//                        if let embedUrl = video.embed_url {
//                            Button("Open in Browser") {
//                                if let url = URL(string: embedUrl) {
//                                    UIApplication.shared.open(url)
//                                }
//                            }
//                            .buttonStyle(ActionButtonStyle(color: .blue))
//                        }
//                        
//                        Button("Retry Player") {
//                            hasError = false
//                            isLoading = true
//                        }
//                        .buttonStyle(ActionButtonStyle(color: .green))
//                    }
//                }
//            } else if isLoading {
//                // Loading state
//                VStack(spacing: 15) {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                        .scaleEffect(1.5)
//                    
//                    Text("Loading video player...")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.white)
//                }
//                .onAppear {
//                    // Simulate loading time and then show player
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        isLoading = false
//                    }
//                }
//            } else {
//                // Video player
//       
//                    // Fallback player UI
//                    Rectangle()
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    Color.blue.opacity(0.4),
//                                    Color.purple.opacity(0.3)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .overlay(
//                            VStack(spacing: 20) {
//                                Image(systemName: "play.rectangle.fill")
//                                    .font(.system(size: 80))
//                                    .foregroundColor(.white)
//                                
//                                Text("Video Player")
//                                    .font(.system(size: 24, weight: .bold))
//                                    .foregroundColor(.white)
//                                
//                                Text(video.name)
//                                    .font(.system(size: 16, weight: .medium))
//                                    .foregroundColor(.white.opacity(0.8))
//                                    .multilineTextAlignment(.center)
//                                    .lineLimit(2)
//                                
//                                if let duration = video.duration {
//                                    Text("Duration: \(formatDuration(duration))")
//                                        .font(.system(size: 14, weight: .medium))
//                                        .foregroundColor(.white.opacity(0.6))
//                                }
//                            }
//                        )
//                        .cornerRadius(12)
//                }
//            }
//        
//        .frame(height: 400)
//    }
//    
//    private func formatDuration(_ seconds: Int) -> String {
//        let minutes = seconds / 60
//        let remainingSeconds = seconds % 60
//        return "\(minutes):\(String(format: "%02d", remainingSeconds))"
//    }
//}
