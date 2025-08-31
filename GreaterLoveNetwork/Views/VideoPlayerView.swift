import SwiftUI
import AVKit

// MARK: - Enhanced Video Player with Continue Watching Support (Fixed)
struct VideoDataPlayerView: View {
    let videoData: VideoData
    @StateObject private var progressManager = WatchProgressManager.shared
    @EnvironmentObject var apiService: CastrAPIService
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
    @State private var hasResumedFromProgress = false
    @State private var showResumePrompt = false
    @State private var savedProgress: WatchProgress?
    @State private var hasAppeared = false
    @State private var showName: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoadingVideo {
                loadingView
            } else if let mp4URL = mp4URL, let url = URL(string: mp4URL) {
                videoPlayerView(url: url)
            } else {
                errorView
            }
            
            // Resume watching prompt
            if showResumePrompt, let progress = savedProgress {
                resumePromptOverlay(progress: progress)
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                findShowForVideo()
                checkForSavedProgress()
                loadVideoURL()
                startControlsTimer()
            }
        }
        .onDisappear {
            saveCurrentProgress()
            controlsTimer?.invalidate()
            cleanupPlayer()
        }
    }
    
    // MARK: - Find Show Name for Better Progress Tracking
    
    private func findShowForVideo() {
        // Find the show that contains this episode
        if let show = apiService.findShow(containing: videoData._id) {
            showName = show.displayName
            print("Found show for video: \(show.displayName)")
        } else {
            // Fallback: try to extract show name from filename
            let filename = videoData.fileName.replacingOccurrences(of: ".mp4", with: "")
            
            // Common patterns to extract show names
            let showPatterns = [
                "CT Townsend",
                "Truth Matters",
                "Sandra Hancock",
                "Ignited Church",
                "Fresh Oil",
                "Grace Pointe",
                "Evangelistic",
                "Higher Praise",
                "Second Chances"
            ]
            
            for pattern in showPatterns {
                if filename.lowercased().contains(pattern.lowercased()) {
                    showName = pattern
                    break
                }
            }
            
            print("Extracted show name from filename: \(showName ?? "Unknown")")
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
            
            Text("Loading video...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 40) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 100))
                .foregroundColor(.orange)
            
            Text("Video not available")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
            
            Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("The video content is currently unavailable or the URL could not be extracted.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func videoPlayerView(url: URL) -> some View {
        ZStack {
            VideoPlayer(player: player)
                .onTapGesture {
                    toggleControlsVisibility()
                }
                .onAppear {
                    if player == nil {
                        setupPlayer(with: url)
                    }
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
                customControlsOverlay
            }
        }
    }
    
    private var customControlsOverlay: some View {
        VStack {
            // Top Controls
            HStack {
                Button(action: {
                    saveCurrentProgress()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    
                    HStack(spacing: 4) {
                        if let showName = showName {
                            Text(showName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("•")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        if let duration = videoData.mediaInfo?.durationMins {
                            Text("\(duration) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        
                        if progressManager.hasProgress(for: videoData._id) {
                            Text("•")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("In Progress")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
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
                        
                        if duration > 0 {
                            Text("-\(formatTime(duration - currentTime))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        } else {
                            Text(formatTime(duration))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Progress Slider with Continue Watching Indicator
                    ProgressSliderWithHistory(
                        value: $currentTime,
                        maxValue: duration,
                        watchProgress: progressManager.getProgress(for: videoData._id),
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
    
    private func resumePromptOverlay(progress: WatchProgress) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Continue Watching?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You were at \(progress.formattedCurrentTime) of \(progress.formattedDuration)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("\(Int(progress.progressPercentage))% completed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                    
                    if let showName = progress.showName {
                        Text("from \(showName)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 30) {
                    Button(action: {
                        startFromBeginning()
                    }) {
                        Text("Start Over")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        resumeFromProgress()
                    }) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(40)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 100)
        }
    }
    
    // MARK: - Continue Watching Logic with Enhanced Show Tracking
    
    private func checkForSavedProgress() {
        savedProgress = progressManager.getProgress(for: videoData._id)
        if savedProgress != nil {
            showResumePrompt = true
        }
    }
    
    private func resumeFromProgress() {
        guard let progress = savedProgress else { return }
        showResumePrompt = false
        hasResumedFromProgress = true
        
        // Set the current time to resume from
        currentTime = progress.currentTime
        
        // If player is already set up, seek to the saved position
        if let player = player {
            let cmTime = CMTime(seconds: progress.currentTime, preferredTimescale: 1)
            player.seek(to: cmTime)
            player.play()
        }
    }
    
    private func startFromBeginning() {
        showResumePrompt = false
        hasResumedFromProgress = true
        currentTime = 0
        
        // Remove the saved progress since user chose to start over
        progressManager.removeProgress(for: videoData._id)
        
        if let player = player {
            player.seek(to: .zero)
            player.play()
        }
    }
    
    private func saveCurrentProgress() {
        guard duration > 0 && currentTime > 0 else { return }
        
        let episodeTitle = videoData.fileName.replacingOccurrences(of: ".mp4", with: "")
        
        print("Saving progress for episode: \(episodeTitle)")
        print("Show name: \(showName ?? "Unknown")")
        print("Current time: \(currentTime), Duration: \(duration)")
        
        // Use the enhanced progress manager with show name
        progressManager.updateProgress(
            for: videoData._id,
            currentTime: currentTime,
            duration: duration,
            episodeTitle: episodeTitle,
            showName: showName
        )
    }
    
    // MARK: - Player Setup and Management
    
    private func setupPlayer(with url: URL) {
        guard player == nil else { return }
        
        print("Setting up player with URL: \(url)")
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Configure player for better video playback
        player?.automaticallyWaitsToMinimizeStalling = true
        player?.allowsExternalPlayback = true
        
        // Setup buffering observation
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            self.isBuffering = true
        }
        
        // Setup ready to play observation
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            self.isBuffering = false
        }
        
        // Setup time observation
        self.playerTimeObserver = self.player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            DispatchQueue.main.async {
                guard let player = self.player else { return }
                
                self.currentTime = time.seconds
                if let duration = player.currentItem?.duration.seconds, !duration.isNaN {
                    self.duration = duration
                    
                    // Auto-resume if we have saved progress and haven't resumed yet
                    if !self.hasResumedFromProgress, let progress = self.savedProgress, !self.showResumePrompt {
                        let cmTime = CMTime(seconds: progress.currentTime, preferredTimescale: 1)
                        player.seek(to: cmTime)
                        self.hasResumedFromProgress = true
                    }
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
                
                // Save progress every 10 seconds while playing
                if self.isPlaying && Int(self.currentTime) % 10 == 0 && self.currentTime > 0 {
                    self.saveCurrentProgress()
                }
            }
        }
        
        // Don't auto-play if we're showing resume prompt
        if !showResumePrompt {
            self.player?.play()
        }
    }
    
    private func cleanupPlayer() {
        guard player != nil else { return }
        
        saveCurrentProgress()
        player?.pause()
        controlsTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
    }
    
    // MARK: - Video URL Loading with Fixed Method Call
    
    private func loadVideoURL() {
        guard let embedURL = videoData.playback?.embed_url else {
            DispatchQueue.main.async {
                self.isLoadingVideo = false
            }
            return
        }
        
        print("Loading video URL from embed: \(embedURL)")
        
        // Use the API service method (fixed method name)
        apiService.extractMP4URL(from: embedURL) { extractedURL in
            DispatchQueue.main.async {
                if let extractedURL = extractedURL {
                    print("Successfully extracted video URL: \(extractedURL)")
                    self.mp4URL = extractedURL
                } else {
                    print("Failed to extract video URL")
                }
                self.isLoadingVideo = false
            }
        }
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
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

// MARK: - Progress Slider with Enhanced History Display
struct ProgressSliderWithHistory: View {
    @Binding var value: Double
    let maxValue: Double
    let watchProgress: WatchProgress?
    let onEditingChanged: (Bool) -> Void
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Previous watch progress (if any) - shown in orange
                if let progress = watchProgress, maxValue > 0 {
                    Rectangle()
                        .fill(Color.orange.opacity(0.6))
                        .frame(width: geometry.size.width * CGFloat(progress.currentTime / maxValue), height: 4)
                        .cornerRadius(2)
                }
                
                // Current progress track - shown in red
                Rectangle()
                    .fill(Color.red)
                    .frame(width: progressWidth(geometry.size.width), height: 4)
                    .cornerRadius(2)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isFocused ? 16 : 12, height: isFocused ? 16 : 12)
                    .offset(x: progressWidth(geometry.size.width) - (isFocused ? 8 : 6))
                    .animation(.easeInOut(duration: 0.1), value: isFocused)
                
                // Previous position indicator (small orange circle)
                if let progress = watchProgress, maxValue > 0 {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: geometry.size.width * CGFloat(progress.currentTime / maxValue) - 4)
                }
            }
        }
        .frame(height: 20)
        .focusable()
        .focused($isFocused)
        .onMoveCommand { direction in
            let step = maxValue / 100
            switch direction {
            case .left:
                value = max(0, value - step)
                onEditingChanged(false)
            case .right:
                value = min(maxValue, value + step)
                onEditingChanged(false)
            default:
                break
            }
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return totalWidth * CGFloat(value / maxValue)
    }
}
