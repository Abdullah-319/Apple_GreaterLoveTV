import SwiftUI
import AVKit

// MARK: - Complete Fixed Live TV Player
struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @State private var connectionState: ConnectionState = .connecting
    @State private var retryAttempts = 0
    @State private var showRetryButton = false
    @State private var lastTimeUpdate: Double = 0
    @State private var stuckFrameDetected = false
    @State private var hasSetupCompleted = false
    @Environment(\.presentationMode) var presentationMode
    
    enum ConnectionState {
        case connecting
        case connected
        case buffering
        case failed
        case retrying
        case stuckOnFrame
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
               let url = URL(string: hlsURL) {
                
                // Main video player
                VideoPlayer(player: player)
                    .onAppear {
                        if !hasSetupCompleted {
                            hasSetupCompleted = true
                            setupLivePlayerWithDelay(with: url)
                        }
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                
                // Connection status overlay
                if connectionState != .connected || stuckFrameDetected {
                    connectionStatusOverlay
                }
                
                // Top navigation overlay (always visible)
                topNavigationOverlay
                
            } else {
                noURLErrorView
            }
        }
    }
    
    // MARK: - UI Components
    
    private var connectionStatusOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text(getConnectionStatusText())
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            if connectionState == .retrying {
                Text("Attempt \(retryAttempts) of 3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            if connectionState == .stuckOnFrame {
                VStack(spacing: 10) {
                    Text("Stream appears stuck on first frame")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Button(action: {
                        forceStreamRestart()
                    }) {
                        Text("Force Restart")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if connectionState == .failed && showRetryButton {
                Button(action: {
                    performRetry()
                }) {
                    Text("Retry Connection")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
    
    private var topNavigationOverlay: some View {
        VStack {
            HStack {
                Button(action: {
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
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stream.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(getStatusColor())
                            .frame(width: 8, height: 8)
                        
                        Text(getStatusDisplayText())
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
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
        }
    }
    
    private var noURLErrorView: some View {
        VStack(spacing: 40) {
            Image(systemName: "tv.circle")
                .font(.system(size: 120))
                .foregroundColor(.red)
            
            Text(stream.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Live Stream Unavailable")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
            
            Text("No stream URL available")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Go Back")
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
    
    // MARK: - Helper Methods
    
    private func getConnectionStatusText() -> String {
        switch connectionState {
        case .connecting:
            return "Connecting to live stream..."
        case .connected:
            return "Connected - Stream Playing"
        case .buffering:
            return "Buffering stream data..."
        case .retrying:
            return "Reconnecting to stream..."
        case .failed:
            return "Connection failed"
        case .stuckOnFrame:
            return "Stream stuck - attempting fix..."
        }
    }
    
    private func getStatusColor() -> Color {
        switch connectionState {
        case .connecting, .retrying, .buffering:
            return .orange
        case .connected:
            return .green
        case .failed:
            return .red
        case .stuckOnFrame:
            return .yellow
        }
    }
    
    private func getStatusDisplayText() -> String {
        switch connectionState {
        case .connecting:
            return "CONNECTING"
        case .connected:
            return "LIVE"
        case .buffering:
            return "BUFFERING"
        case .retrying:
            return "RECONNECTING"
        case .failed:
            return "OFFLINE"
        case .stuckOnFrame:
            return "STUCK"
        }
    }
    
    // MARK: - Fixed Player Setup with Proper Initialization
    
    private func setupLivePlayerWithDelay(with url: URL) {
        connectionState = .connecting
        stuckFrameDetected = false
        
        // Add a small delay to ensure proper initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupLivePlayer(with: url)
        }
    }
    
    private func setupLivePlayer(with url: URL) {
        // Create optimized live URL
        let liveURL = ensureLiveURL(url)
        let playerItem = AVPlayerItem(url: liveURL)
        
        // Configure for live streaming with minimal buffering
        playerItem.preferredForwardBufferDuration = 1.0
        playerItem.preferredPeakBitRate = 0
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        
        guard let player = player else {
            connectionState = .failed
            showRetryButton = true
            return
        }
        
        // Configure player for live streaming
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = false
        
        // Setup comprehensive monitoring
        setupPlayerMonitoring(for: player, playerItem: playerItem)
        
        // Wait for asset to load before attempting to play
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
            DispatchQueue.main.async {
                var error: NSError? = nil
                let status = playerItem.asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    // Asset loaded successfully - start playback
                    self.startLivePlayback()
                } else {
                    // Asset loading failed - try direct play anyway
                    player.play()
                    
                    // Check after delay if playback started
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if player.rate == 0 {
                            self.seekToLiveEdgeAndPlay()
                        }
                    }
                }
            }
        }
    }
    
    private func setupPlayerMonitoring(for player: AVPlayer, playerItem: AVPlayerItem) {
        // Remove existing observers first
        NotificationCenter.default.removeObserver(self)
        
        // Setup notifications for live streaming
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                self.connectionState = .buffering
                self.handleStreamStall()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                self.connectionState = .connected
                self.isBuffering = false
                self.retryAttempts = 0
                self.showRetryButton = false
                self.stuckFrameDetected = false
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                DispatchQueue.main.async {
                    self.handleStreamError(error)
                }
            }
        }
        
        // Setup time observer for monitoring
        playerTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            DispatchQueue.main.async {
                self.monitorPlayerHealth(currentTime: time.seconds)
            }
        }
    }
    
    private func monitorPlayerHealth(currentTime: Double) {
        guard let player = player,
              let currentItem = player.currentItem else {
            return
        }
        
        let status = currentItem.status
        let isLikelyToKeepUp = currentItem.isPlaybackLikelyToKeepUp
        let isBufferEmpty = currentItem.isPlaybackBufferEmpty
        let rate = player.rate
        
        switch status {
        case .readyToPlay:
            if isLikelyToKeepUp && rate > 0 && currentTime > 0 {
                if connectionState != .connected {
                    connectionState = .connected
                    isBuffering = false
                    stuckFrameDetected = false
                }
            } else if isBufferEmpty || !isLikelyToKeepUp {
                if connectionState == .connected {
                    connectionState = .buffering
                    isBuffering = true
                }
            }
            
            // Check for stuck frame condition
            if rate == 0 && currentTime > 0 && !stuckFrameDetected {
                player.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if player.rate == 0 {
                        self.seekToLiveEdgeAndPlay()
                    }
                }
            }
            
        case .failed:
            handleStreamError(currentItem.error ?? NSError(domain: "LiveStream", code: -1, userInfo: nil))
            
        case .unknown:
            // Wait for status to change
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Fixed Playback Methods
    
    private func startLivePlayback() {
        guard let player = player else { return }
        
        // Try to play immediately
        player.play()
        
        // Check if playback started after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if player.rate == 0 {
                // If not playing, try seeking to live edge first
                self.seekToLiveEdgeAndPlay()
            } else {
                // Playing successfully
                self.connectionState = .connected
            }
        }
    }
    
    private func seekToLiveEdgeAndPlay() {
        guard let player = player,
              let currentItem = player.currentItem else {
            return
        }
        
        let seekableRanges = currentItem.seekableTimeRanges
        
        if !seekableRanges.isEmpty,
           let lastRange = seekableRanges.last?.timeRangeValue {
            
            // Calculate live edge (end of seekable range)
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            
            // Seek to live edge
            player.seek(to: liveEdge) { completed in
                DispatchQueue.main.async {
                    if completed {
                        // Now start playing from live edge
                        player.play()
                        
                        // Verify playback started
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if player.rate > 0 {
                                self.connectionState = .connected
                                self.stuckFrameDetected = false
                            } else {
                                // Try setting rate directly
                                player.rate = 1.0
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if player.rate > 0 {
                                        self.connectionState = .connected
                                    } else {
                                        self.connectionState = .failed
                                        self.showRetryButton = true
                                    }
                                }
                            }
                        }
                    } else {
                        // Seek failed, try direct play
                        player.play()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if player.rate == 0 {
                                self.connectionState = .failed
                                self.showRetryButton = true
                            }
                        }
                    }
                }
            }
        } else {
            // No seekable ranges, try direct play
            player.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if player.rate == 0 {
                    // Try setting rate directly as last resort
                    player.rate = 1.0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if player.rate == 0 {
                            self.connectionState = .failed
                            self.showRetryButton = true
                        }
                    }
                }
            }
        }
    }
    
    private func ensureLiveURL(_ url: URL) -> URL {
        var urlString = url.absoluteString
        
        // Add live streaming parameters if not present
        if !urlString.contains("?") {
            urlString += "?_HLS_msn=0&_HLS_part=0"
        } else if !urlString.contains("_HLS_") {
            urlString += "&_HLS_msn=0&_HLS_part=0"
        }
        
        return URL(string: urlString) ?? url
    }
    
    private func handleStreamStall() {
        guard let player = player,
              let currentItem = player.currentItem else {
            return
        }
        
        let seekableRanges = currentItem.seekableTimeRanges
        
        if !seekableRanges.isEmpty,
           let lastRange = seekableRanges.last?.timeRangeValue {
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            
            player.seek(to: liveEdge) { completed in
                DispatchQueue.main.async {
                    if completed {
                        player.play()
                        self.connectionState = .connected
                    } else {
                        player.play()
                        self.connectionState = .buffering
                    }
                }
            }
        } else {
            player.play()
            connectionState = .buffering
        }
    }
    
    private func handleStreamError(_ error: Error) {
        if retryAttempts < 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performRetry()
            }
        } else {
            connectionState = .failed
            showRetryButton = true
        }
    }
    
    private func forceStreamRestart() {
        guard let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
              let url = URL(string: hlsURL) else {
            connectionState = .failed
            showRetryButton = true
            return
        }
        
        stuckFrameDetected = false
        connectionState = .connecting
        
        cleanupPlayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupLivePlayer(with: url)
        }
    }
    
    private func performRetry() {
        guard let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
              let url = URL(string: hlsURL) else {
            connectionState = .failed
            showRetryButton = true
            return
        }
        
        retryAttempts += 1
        connectionState = .retrying
        showRetryButton = false
        stuckFrameDetected = false
        
        cleanupPlayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.retryAttempts <= 3 {
                self.setupLivePlayer(with: url)
            } else {
                self.connectionState = .failed
                self.showRetryButton = true
            }
        }
    }
    
    private func cleanupPlayer() {
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
        
        player?.pause()
        player = nil
        
        isBuffering = false
    }
}
