import SwiftUI
import AVKit

// MARK: - Enhanced Video Player with Custom Controls
struct VideoDataPlayerView: View {
    let videoData: VideoData
    @State private var player: AVPlayer?
    @State private var mp4URL: String?
    @State private var isLoadingVideo = true
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoadingVideo {
                // Loading State
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("Loading video...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(videoData.fileName)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if let mp4URL = mp4URL, let url = URL(string: mp4URL) {
                // Video Player with Controls
                ZStack {
                    VideoPlayer(player: player)
                        .onTapGesture {
                            toggleControlsVisibility()
                        }
                        .onAppear {
                            setupPlayer(with: url)
                        }
                        .onDisappear {
                            cleanupPlayer()
                        }
                    
                    // Buffering Overlay
                    if isBuffering {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Buffering...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.7))
                    }
                    
                    // Custom Controls Overlay
                    if showControls {
                        VStack {
                            // Top Controls
                            HStack {
                                CTAButton(title: "Back") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    if let duration = videoData.mediaInfo?.durationMins {
                                        Text("\(duration) min")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 50)
                            .padding(.top, 50)
                            
                            Spacer()
                            
                            // Bottom Controls
                            VStack(spacing: 20) {
                                // Progress Bar Section
                                VStack(spacing: 8) {
                                    // Time Labels
                                    HStack {
                                        Text(formatTime(currentTime))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(formatTime(duration))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Progress Slider
                                    ProgressSlider(
                                        value: $currentTime,
                                        maxValue: duration,
                                        onEditingChanged: { editing in
                                            if !editing {
                                                seekToTime(currentTime)
                                            }
                                        }
                                    )
                                }
                                
                                // Control Buttons
                                HStack(spacing: 60) {
                                    VideoControlButton(
                                        systemName: "gobackward.10",
                                        action: { seekBackward() }
                                    )
                                    
                                    VideoControlButton(
                                        systemName: isPlaying ? "pause.fill" : "play.fill",
                                        size: 60,
                                        action: { togglePlayPause() }
                                    )
                                    
                                    VideoControlButton(
                                        systemName: "goforward.10",
                                        action: { seekForward() }
                                    )
                                }
                            }
                            .padding(.horizontal, 50)
                            .padding(.bottom, 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .transition(.opacity)
                    }
                }
            } else {
                // Fallback Error State
                VStack(spacing: 40) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.orange)
                    
                    Text("Video not available")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(videoData.fileName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("The video content is currently unavailable or the embed URL is missing.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                }
            }
        }
        .onAppear {
            loadVideoURL()
            startControlsTimer()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
    }
    
    // MARK: - Player Setup and Management
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup buffering observation
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            isBuffering = true
        }
        
        // Setup time observation
        playerTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            DispatchQueue.main.async {
                guard let player = self.player else { return }
                
                self.currentTime = time.seconds
                if let duration = player.currentItem?.duration.seconds, !duration.isNaN {
                    self.duration = duration
                }
                
                // Update playing state
                self.isPlaying = player.rate > 0
                
                // Update buffering state
                if let item = player.currentItem {
                    if item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp {
                        self.isBuffering = false
                    } else if item.status == .readyToPlay && !item.isPlaybackLikelyToKeepUp {
                        self.isBuffering = true
                    }
                }
            }
        }
        
        player?.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        controlsTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
    }
    
    // MARK: - Video URL Loading
    private func loadVideoURL() {
        guard let embedURL = videoData.playback?.embed_url else {
            isLoadingVideo = false
            return
        }
        
        extractVideoURLFromEmbed(embedURL)
    }
    
    private func extractVideoURLFromEmbed(_ embedURL: String) {
        guard let url = URL(string: embedURL) else {
            isLoadingVideo = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                }
                return
            }
            
            // Multiple regex patterns to extract video URLs
            let patterns = [
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^/]+\.mp4/index\.m3u8"#,
                #"https://[^"'\s]*\.m3u8[^"'\s]*"#,
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^"'\s]*\.mp4"#,
                #"src\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"file\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#
            ]
            
            for pattern in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: htmlString.count)
                
                if let match = regex?.firstMatch(in: htmlString, options: [], range: range) {
                    var extractedURL: String
                    
                    if match.numberOfRanges > 1 {
                        let urlRange = Range(match.range(at: 1), in: htmlString)!
                        extractedURL = String(htmlString[urlRange])
                    } else {
                        let urlRange = Range(match.range, in: htmlString)!
                        extractedURL = String(htmlString[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    }
                    
                    DispatchQueue.main.async {
                        self.mp4URL = extractedURL
                        self.isLoadingVideo = false
                    }
                    return
                }
            }
            
            // Fallback URL construction for Castr player
            if embedURL.contains("player.castr.com/vod/") {
                let components = embedURL.components(separatedBy: "/")
                if let videoId = components.last {
                    let possibleURLs = [
                        "https://cstr-vod.castr.com/videos/\(videoId)/index.m3u8",
                        "https://player.castr.io/\(videoId).mp4"
                    ]
                    
                    for testURL in possibleURLs {
                        DispatchQueue.main.async {
                            self.mp4URL = testURL
                            self.isLoadingVideo = false
                        }
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isLoadingVideo = false
            }
        }.resume()
    }
    
    // MARK: - Video Control Functions
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
        resetControlsTimer()
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        player.seek(to: cmTime)
        resetControlsTimer()
    }
    
    // MARK: - Controls Visibility Management
    private func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        showControls = true
        startControlsTimer()
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds.isFinite else { return "00:00" }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
