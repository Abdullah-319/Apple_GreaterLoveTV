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
    @State private var debugInfo: [String] = []
    @State private var lastTimeUpdate: Double = 0
    @State private var stuckFrameDetected = false
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
                        addDebugLog("VideoPlayer appeared - setting up live player")
                        setupLivePlayer(with: url)
                    }
                    .onDisappear {
                        addDebugLog("VideoPlayer disappeared - cleaning up")
                        cleanupPlayer()
                    }
                
                // Connection status overlay
                if connectionState != .connected || stuckFrameDetected {
                    connectionStatusOverlay
                }
                
                // Top navigation overlay (always visible)
                topNavigationOverlay
                
                // Debug overlay (bottom right)
                debugOverlay
                
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
                    addDebugLog("Back button pressed")
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
    
    private var debugOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(Array(debugInfo.suffix(5).enumerated()), id: \.offset) { index, log in
                        Text(log)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
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
    
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.timeFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        print("LIVE_STREAM_DEBUG: \(logMessage)")
        
        DispatchQueue.main.async {
            self.debugInfo.append(logMessage)
            if self.debugInfo.count > 20 {
                self.debugInfo.removeFirst()
            }
        }
    }
    
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
    
    // MARK: - Fixed Player Setup Method
    
    private func setupLivePlayer(with url: URL) {
        addDebugLog("Setting up live player with URL: \(url.absoluteString)")
        
        connectionState = .connecting
        stuckFrameDetected = false
        
        // CRITICAL FIX: Create player item with live URL modification
        let liveURL = ensureLiveURL(url)
        let playerItem = AVPlayerItem(url: liveURL)
        addDebugLog("Created AVPlayerItem with live URL: \(liveURL.absoluteString)")
        
        // AGGRESSIVE LIVE SETTINGS - This fixes the stuck frame issue
        playerItem.preferredForwardBufferDuration = 0.0  // Zero buffer for live
        playerItem.preferredPeakBitRate = 0
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        addDebugLog("Created AVPlayer")
        
        guard let player = player else {
            addDebugLog("ERROR: Failed to create AVPlayer")
            connectionState = .failed
            showRetryButton = true
            return
        }
        
        // CRITICAL LIVE SETTINGS
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = false
        
        addDebugLog("Configured aggressive live settings")
        
        // Setup monitoring
        setupAdvancedPlayerMonitoring(for: player, playerItem: playerItem)
        
        // MAIN FIX: Wait for asset to load, then seek to live edge BEFORE playing
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) {
            DispatchQueue.main.async {
                var error: NSError? = nil
                let status = playerItem.asset.statusOfValue(forKey: "duration", error: &error)
                
                self.addDebugLog("Asset loading status: \(status.rawValue)")
                
                if status == .loaded {
                    self.addDebugLog("Asset loaded successfully - seeking to live edge first")
                    self.seekToLiveEdgeThenPlay()
                } else {
                    self.addDebugLog("Asset loading failed or cancelled - trying direct play")
                    player.play()
                    
                    // Fallback: seek after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.forceSeekToLiveEdge()
                    }
                }
            }
        }
    }
    
    private func setupAdvancedPlayerMonitoring(for player: AVPlayer, playerItem: AVPlayerItem) {
        addDebugLog("Setting up player monitoring...")
        
        // Comprehensive notification setup
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            self.addDebugLog("NOTIFICATION: Playback stalled")
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
            self.addDebugLog("NOTIFICATION: New access log entry - stream working")
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
                self.addDebugLog("NOTIFICATION: Failed to play - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.handleStreamError(error)
                }
            }
        }
        
        // Enhanced time observer with stuck frame detection
        playerTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            DispatchQueue.main.async {
                self.monitorPlayerHealthWithDebug(currentTime: time.seconds)
            }
        }
        
        addDebugLog("Player monitoring setup complete")
    }
    
    private func monitorPlayerHealthWithDebug(currentTime: Double) {
        guard let player = player,
              let currentItem = player.currentItem else {
            return
        }
        
        let status = currentItem.status
        let isLikelyToKeepUp = currentItem.isPlaybackLikelyToKeepUp
        let isBufferEmpty = currentItem.isPlaybackBufferEmpty
        let rate = player.rate
        let loadedTimeRanges = currentItem.loadedTimeRanges
        let seekableTimeRanges = currentItem.seekableTimeRanges
        
        // Enhanced logging every 3 seconds
        let now = Date().timeIntervalSince1970
        if now - lastTimeUpdate > 3.0 {
            addDebugLog("Monitor: Status=\(statusString(status)), Rate=\(rate), Time=\(currentTime)")
            addDebugLog("Monitor: KeepUp=\(isLikelyToKeepUp), BufferEmpty=\(isBufferEmpty)")
            addDebugLog("Monitor: Loaded=\(loadedTimeRanges.count), Seekable=\(seekableTimeRanges.count)")
            
            // Log seekable range details
            if !seekableTimeRanges.isEmpty {
                let range = seekableTimeRanges.last?.timeRangeValue
                let start = range?.start.seconds ?? 0
                let duration = range?.duration.seconds ?? 0
                addDebugLog("Monitor: Seekable range: \(start) to \(start + duration)")
            }
            
            lastTimeUpdate = now
        }
        
        // Detect various stuck conditions
        if status == .readyToPlay && rate == 0 && currentTime > 0 && !stuckFrameDetected {
            addDebugLog("ISSUE: Player ready but not playing - forcing play")
            player.play()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if player.rate == 0 {
                    self.addDebugLog("ISSUE: Force play failed - seeking to live edge")
                    self.forceSeekToLiveEdge()
                }
            }
        }
        
        switch status {
        case .readyToPlay:
            if isLikelyToKeepUp && rate > 0 && currentTime > 0 {
                if connectionState != .connected {
                    addDebugLog("SUCCESS: Stream playing successfully")
                    connectionState = .connected
                    isBuffering = false
                    stuckFrameDetected = false
                }
            } else if isBufferEmpty || !isLikelyToKeepUp {
                if connectionState == .connected {
                    addDebugLog("Stream buffering...")
                    connectionState = .buffering
                    isBuffering = true
                }
            }
            
        case .failed:
            let errorMsg = currentItem.error?.localizedDescription ?? "Unknown error"
            addDebugLog("Player failed: \(errorMsg)")
            handleStreamError(currentItem.error ?? NSError(domain: "LiveStream", code: -1, userInfo: nil))
            
        case .unknown:
            // Status unknown is normal initially, but problematic if it persists
            if now - lastTimeUpdate > 10.0 && currentTime > 0 {
                addDebugLog("WARNING: Status unknown for too long - may need restart")
                if !seekableTimeRanges.isEmpty {
                    forceSeekToLiveEdge()
                }
            }
            
        @unknown default:
            addDebugLog("Player status: unknown default case")
            break
        }
    }
    
    // MARK: - Critical Fix Methods
    
    private func ensureLiveURL(_ url: URL) -> URL {
        var urlString = url.absoluteString
        
        // Add live streaming parameters if not present
        if !urlString.contains("?") {
            urlString += "?_HLS_msn=0&_HLS_part=0"  // Force live edge
        } else if !urlString.contains("_HLS_") {
            urlString += "&_HLS_msn=0&_HLS_part=0"
        }
        
        addDebugLog("Modified URL for live streaming: \(urlString)")
        return URL(string: urlString) ?? url
    }
    
    private func seekToLiveEdgeThenPlay() {
        guard let player = player,
              let currentItem = player.currentItem else {
            addDebugLog("SeekThenPlay: No player or item")
            return
        }
        
        // Wait a moment for seekable ranges to populate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let seekableRanges = currentItem.seekableTimeRanges
            self.addDebugLog("SeekThenPlay: Found \(seekableRanges.count) seekable ranges")
            
            if !seekableRanges.isEmpty,
               let lastRange = seekableRanges.last?.timeRangeValue {
                
                // Calculate live edge
                let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
                let liveEdgeSeconds = liveEdge.seconds
                
                self.addDebugLog("SeekThenPlay: Live edge at \(liveEdgeSeconds) seconds")
                
                // Seek to live edge first
                player.seek(to: liveEdge) { completed in
                    DispatchQueue.main.async {
                        self.addDebugLog("SeekThenPlay: Seek completed: \(completed)")
                        
                        // NOW start playing from live edge
                        player.play()
                        self.addDebugLog("SeekThenPlay: Started playing from live edge")
                        
                        // Monitor if this worked
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            let rate = player.rate
                            let newTime = player.currentTime().seconds
                            self.addDebugLog("SeekThenPlay: After 2s - Rate: \(rate), Time: \(newTime)")
                            
                            if rate > 0 && newTime > liveEdgeSeconds - 5 {
                                self.addDebugLog("SUCCESS: Live stream playing from correct position")
                                self.connectionState = .connected
                                self.stuckFrameDetected = false
                            } else {
                                self.addDebugLog("FAILED: Still not playing correctly")
                                self.tryForceRate()
                            }
                        }
                    }
                }
            } else {
                self.addDebugLog("SeekThenPlay: No seekable ranges - direct play")
                player.play()
                
                // Check if this works
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if player.rate == 0 {
                        self.addDebugLog("Direct play failed - trying force rate")
                        self.tryForceRate()
                    }
                }
            }
        }
    }
    
    private func forceSeekToLiveEdge() {
        guard let player = player,
              let currentItem = player.currentItem else {
            addDebugLog("ForceSeek: No player or item")
            return
        }
        
        let seekableRanges = currentItem.seekableTimeRanges
        addDebugLog("ForceSeek: Found \(seekableRanges.count) seekable ranges")
        
        if !seekableRanges.isEmpty,
           let lastRange = seekableRanges.last?.timeRangeValue {
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            let liveEdgeSeconds = liveEdge.seconds
            
            addDebugLog("ForceSeek: Seeking to live edge at \(liveEdgeSeconds) seconds")
            
            player.seek(to: liveEdge) { completed in
                DispatchQueue.main.async {
                    self.addDebugLog("ForceSeek: Seek completed: \(completed)")
                    if completed {
                        self.addDebugLog("ForceSeek: Starting playback after seek")
                        player.play()
                        
                        // Verify playback started
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            let newRate = player.rate
                            self.addDebugLog("ForceSeek: Rate after seek: \(newRate)")
                            
                            if newRate > 0 {
                                self.connectionState = .connected
                                self.stuckFrameDetected = false
                            }
                        }
                    } else {
                        self.addDebugLog("ForceSeek: Seek failed - trying alternative approach")
                        self.tryAlternativePlayback()
                    }
                }
            }
        } else {
            addDebugLog("ForceSeek: No seekable ranges - trying direct play")
            player.play()
        }
    }
    
    private func tryForceRate() {
        guard let player = player else { return }
        
        addDebugLog("Trying to force player rate to 1.0")
        
        // Pause first, then set rate directly
        player.pause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player.rate = 1.0
            self.addDebugLog("Set rate directly to 1.0")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let actualRate = player.rate
                let currentTime = player.currentTime().seconds
                self.addDebugLog("ForceRate result: Rate=\(actualRate), Time=\(currentTime)")
                
                if actualRate > 0 {
                    self.connectionState = .connected
                    self.stuckFrameDetected = false
                } else {
                    self.addDebugLog("Force rate failed - stream may be incompatible")
                    self.connectionState = .failed
                    self.showRetryButton = true
                }
            }
        }
    }
    
    private func tryAlternativePlayback() {
        guard let player = player else { return }
        
        addDebugLog("Trying alternative playback approach...")
        
        // Try setting a different rate
        player.rate = 1.0
        addDebugLog("Set player rate to 1.0 directly")
        
        // Wait and check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let newRate = player.rate
            self.addDebugLog("Alternative: New rate is \(newRate)")
            
            if newRate > 0 {
                self.connectionState = .connected
                self.stuckFrameDetected = false
            } else {
                self.addDebugLog("Alternative failed - trying full restart")
                self.performRetry()
            }
        }
    }
    
    private func checkForStuckFrame() {
        guard let player = player,
              let currentItem = player.currentItem else {
            addDebugLog("StuckCheck: No player or item")
            return
        }
        
        let rate = player.rate
        let status = currentItem.status
        let currentTime = player.currentTime().seconds
        
        addDebugLog("StuckCheck: Rate=\(rate), Status=\(statusString(status)), Time=\(currentTime)")
        
        // If player rate is 0 but we have seekable ranges, we're likely stuck
        if rate == 0.0 && !currentItem.seekableTimeRanges.isEmpty {
            addDebugLog("DETECTED: Stream stuck - forcing live edge seek")
            stuckFrameDetected = true
            connectionState = .stuckOnFrame
            forceSeekToLiveEdge()
        }
    }
    
    private func forceStreamRestart() {
        addDebugLog("Force restart requested by user")
        
        guard let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
              let url = URL(string: hlsURL) else {
            addDebugLog("Force restart failed - no URL")
            return
        }
        
        stuckFrameDetected = false
        connectionState = .connecting
        
        // Complete cleanup and restart
        cleanupPlayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.addDebugLog("Starting force restart setup...")
            self.setupLivePlayer(with: url)
        }
    }
    
    private func handleStreamStall() {
        guard let player = player,
              let currentItem = player.currentItem else {
            addDebugLog("HandleStall: No player or item")
            return
        }
        
        addDebugLog("Handling stream stall...")
        
        let seekableRanges = currentItem.seekableTimeRanges
        addDebugLog("Seekable ranges count: \(seekableRanges.count)")
        
        if !seekableRanges.isEmpty,
           let lastRange = seekableRanges.last?.timeRangeValue {
            let liveEdge = CMTimeAdd(lastRange.start, lastRange.duration)
            let liveEdgeSeconds = liveEdge.seconds
            
            addDebugLog("Seeking to live edge: \(liveEdgeSeconds) seconds")
            
            player.seek(to: liveEdge) { completed in
                DispatchQueue.main.async {
                    self.addDebugLog("Seek completed: \(completed)")
                    if completed {
                        player.play()
                        self.addDebugLog("Restarted playback after seek")
                        self.connectionState = .connected
                    } else {
                        self.addDebugLog("Seek failed - trying direct play")
                        player.play()
                        self.connectionState = .buffering
                    }
                }
            }
        } else {
            addDebugLog("No seekable ranges - trying direct play restart")
            player.play()
            connectionState = .buffering
        }
    }
    
    private func handleStreamError(_ error: Error) {
        addDebugLog("Stream error: \(error.localizedDescription)")
        
        if retryAttempts < 3 {
            addDebugLog("Scheduling automatic retry...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performRetry()
            }
        } else {
            addDebugLog("Max retries reached - showing manual retry button")
            connectionState = .failed
            showRetryButton = true
        }
    }
    
    // MARK: - Single Retry Method (Fixed)
    
    private func performRetry() {
        guard let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
              let url = URL(string: hlsURL) else {
            addDebugLog("Retry failed - no valid URL")
            connectionState = .failed
            showRetryButton = true
            return
        }
        
        addDebugLog("Performing retry attempt \(retryAttempts + 1)")
        
        retryAttempts += 1
        connectionState = .retrying
        showRetryButton = false
        stuckFrameDetected = false
        
        cleanupPlayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if self.retryAttempts <= 3 {
                self.addDebugLog("Setting up player for retry...")
                self.setupLivePlayer(with: url)
            } else {
                self.addDebugLog("All retry attempts exhausted")
                self.connectionState = .failed
                self.showRetryButton = true
            }
        }
    }
    
    private func cleanupPlayer() {
        addDebugLog("Starting player cleanup...")
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
            addDebugLog("Removed time observer")
        }
        
        NotificationCenter.default.removeObserver(self)
        addDebugLog("Removed notification observers")
        
        player?.pause()
        addDebugLog("Paused player")
        
        player = nil
        addDebugLog("Released player")
        
        isBuffering = false
        addDebugLog("Player cleanup complete")
    }
    
    // MARK: - Helper Extensions
    
    private func statusString(_ status: AVPlayerItem.Status) -> String {
        switch status {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "failed"
        @unknown default:
            return "unknownDefault"
        }
    }
}

// MARK: - DateFormatter Extension for Debug Timestamps
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
