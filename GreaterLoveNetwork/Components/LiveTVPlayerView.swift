import SwiftUI
import AVKit
import AVFoundation
import Combine

// MARK: - Player Observer Class for KVO
class PlayerObserver: NSObject, ObservableObject {
    @Published var isBuffering = false
    @Published var hasStartedPlaying = false
    @Published var playbackError: Error?
    @Published var playerStatus: AVPlayer.Status = .unknown
    @Published var playerItemStatus: AVPlayerItem.Status = .unknown
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerTimeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // Track observer states to prevent double removal
    private var isObservingPlayer = false
    private var isObservingPlayerItem = false
    
    override init() {
        super.init()
    }
    
    func observe(_ player: AVPlayer) {
        // Clean up any existing observations first
        cleanupObservation()
        
        self.player = player
        
        // Observe player status
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.new, .initial], context: nil)
        isObservingPlayer = true
        
        // Observe player item status if available
        if let playerItem = player.currentItem {
            self.playerItem = playerItem
            playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
            isObservingPlayerItem = true
            setupPlayerItemNotifications(playerItem)
        }
        
        // Monitor playback status
        playerTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] _ in
            self?.checkPlaybackStatus()
        }
    }
    
    private func setupPlayerItemNotifications(_ playerItem: AVPlayerItem) {
        // Observe buffering events
        NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("Live stream stalled - rebuffering...")
                self?.isBuffering = true
            }
            .store(in: &cancellables)
        
        // Observe when ready to play
        NotificationCenter.default.publisher(for: .AVPlayerItemNewAccessLogEntry, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if !(self?.hasStartedPlaying ?? true) {
                    self?.isBuffering = false
                    self?.hasStartedPlaying = true
                    print("Live stream started successfully")
                }
            }
            .store(in: &cancellables)
        
        // Observe errors
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                    print("Live stream failed: \(error.localizedDescription)")
                    self?.playbackError = error
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkPlaybackStatus() {
        guard let player = self.player, let item = player.currentItem else { return }
        
        DispatchQueue.main.async {
            // Check if playback is working
            if item.status == .readyToPlay {
                if item.isPlaybackLikelyToKeepUp && player.rate > 0 {
                    if !self.hasStartedPlaying {
                        self.hasStartedPlaying = true
                    }
                    self.isBuffering = false
                } else if !item.isPlaybackLikelyToKeepUp && self.hasStartedPlaying {
                    self.isBuffering = true
                }
            } else if item.status == .failed {
                self.isBuffering = false
                if let error = item.error {
                    self.playbackError = error
                }
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        DispatchQueue.main.async {
            switch keyPath {
            case #keyPath(AVPlayer.status):
                if let player = object as? AVPlayer, player == self.player {
                    print("Player status changed to: \(player.status.rawValue)")
                    self.playerStatus = player.status
                    if player.status == .failed {
                        if let error = player.error {
                            self.playbackError = error
                        }
                    }
                }
                
            case #keyPath(AVPlayerItem.status):
                if let playerItem = object as? AVPlayerItem, playerItem == self.playerItem {
                    print("PlayerItem status changed to: \(playerItem.status.rawValue)")
                    self.playerItemStatus = playerItem.status
                    switch playerItem.status {
                    case .readyToPlay:
                        print("PlayerItem is ready to play")
                        self.isBuffering = false
                    case .failed:
                        if let error = playerItem.error {
                            self.playbackError = error
                        }
                    case .unknown:
                        print("PlayerItem status is unknown")
                    @unknown default:
                        break
                    }
                }
                
            default:
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }
    }
    
    func cleanupObservation() {
        // Remove KVO observers safely
        if let player = self.player, isObservingPlayer {
            do {
                player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.status))
                isObservingPlayer = false
            } catch {
                print("Warning: Could not remove player observer: \(error)")
            }
        }
        
        if let playerItem = self.playerItem, isObservingPlayerItem {
            do {
                playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
                isObservingPlayerItem = false
            } catch {
                print("Warning: Could not remove player item observer: \(error)")
            }
        }
        
        // Remove notification observers
        cancellables.removeAll()
        
        // Remove time observer
        if let timeObserver = playerTimeObserver, let player = self.player {
            player.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        // Reset references
        self.player = nil
        self.playerItem = nil
    }
    
    deinit {
        cleanupObservation()
    }
}

// MARK: - Enhanced Live TV Player with Fixed HLS Streaming
struct LiveTVPlayerView: View {
    let stream: LiveStream
    @StateObject private var playerObserver = PlayerObserver()
    @State private var player: AVPlayer?
    @State private var playerViewController: AVPlayerViewController?
    @State private var streamURL: URL?
    @State private var isPlayerReady = false
    @State private var connectionRetryCount = 0
    @State private var maxRetryCount = 3
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let error = playerObserver.playbackError {
                errorView(error: error)
            } else if let streamURL = streamURL, isPlayerReady {
                playerView
            } else {
                loadingView
            }
            
            // Enhanced Control Overlay
            VStack {
                topControlsOverlay
                Spacer()
                if playerObserver.hasStartedPlaying {
                    bottomControlsOverlay
                }
            }
            .padding(50)
        }
        .onAppear {
            prepareStreamURL()
        }
        .onDisappear {
            cleanupPlayer()
        }
    }
    
    // MARK: - View Components
    
    private var playerView: some View {
        Group {
            if let playerViewController = playerViewController {
                PlayerViewControllerWrapper(playerViewController: playerViewController)
                    .overlay(
                        Group {
                            if playerObserver.isBuffering && !playerObserver.hasStartedPlaying {
                                bufferingOverlay
                            }
                        }
                    )
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        Text("Initializing Player...")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                    )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2.0)
            
            Text("Preparing live stream...")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            Text(stream.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let status = stream.broadcasting_status {
                statusIndicator(status: status)
            }
        }
    }
    
    private var bufferingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.8)
            
            Text("Connecting to live stream...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 10)
            
            statusIndicator(status: stream.broadcasting_status ?? "connecting")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 40) {
            Image(systemName: "tv.circle")
                .font(.system(size: 120))
                .foregroundColor(.red)
            
            Text("Stream Unavailable")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(stream.name)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button(action: retryConnection) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Retry Connection")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var topControlsOverlay: some View {
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
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 12) {
                    Text(stream.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    statusIndicator(status: stream.broadcasting_status ?? "unknown")
                }
                
                if playerObserver.hasStartedPlaying {
                    Text("Broadcasting live")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                } else if playerObserver.isBuffering {
                    Text("Connecting...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    private var bottomControlsOverlay: some View {
        VStack(spacing: 16) {
            Text("Live Stream Active")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button(action: togglePlayPause) {
                    Image(systemName: playerObserver.hasStartedPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: refreshStream) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func statusIndicator(status: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status == "online" ? Color.red : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(status == "online" ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: status == "online")
            
            Text(status.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(status == "online" ? .red : .gray)
        }
    }
    
    // MARK: - Stream Setup and Management
    
    private func prepareStreamURL() {
        playerObserver.isBuffering = true
        playerObserver.playbackError = nil
        
        // Try different URL sources in order of preference
        var urlToUse: URL?
        
        // First, try HLS URL
        if let hlsURL = stream.hls_url ?? stream.playback?.hls_url {
            urlToUse = URL(string: hlsURL)
        }
        
        // If no HLS URL, try embed URL (less preferred for live streaming)
        if urlToUse == nil, let embedURL = stream.embed_url ?? stream.playback?.embed_url {
            urlToUse = URL(string: embedURL)
        }
        
        guard let finalURL = urlToUse else {
            playerObserver.playbackError = NSError(domain: "LiveStreamError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No valid stream URL found"
            ])
            playerObserver.isBuffering = false
            return
        }
        
        streamURL = finalURL
        setupPlayerWithURL(finalURL)
    }
    
    private func setupPlayerWithURL(_ url: URL) {
        print("Setting up player with URL: \(url)")
        
        // Clean up previous player
        cleanupPlayer()
        
        // Create AVPlayer with optimized settings for live streaming
        let player = AVPlayer(url: url)
        
        // Configure player for live streaming
        player.automaticallyWaitsToMinimizeStalling = false
        player.allowsExternalPlayback = true
        
        // Set preferred peak bit rate for better streaming
        if let currentItem = player.currentItem {
            currentItem.preferredPeakBitRate = 0 // Let AVPlayer choose optimal bitrate
            currentItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        
        // Create player view controller
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        playerVC.showsPlaybackControls = false // We'll use custom controls
        
        self.player = player
        self.playerViewController = playerVC
        
        // Setup observers
        playerObserver.observe(player)
        
        // Mark as ready and start playback
        DispatchQueue.main.async {
            self.isPlayerReady = true
            
            // Start playing after a small delay to ensure everything is set up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startPlayback()
            }
        }
    }
    
    private func startPlayback() {
        guard let player = player else { return }
        
        print("Starting live stream playback...")
        player.play()
        
        // Set a timeout to detect if stream doesn't start
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if !self.playerObserver.hasStartedPlaying && self.playerObserver.isBuffering {
                self.handlePlaybackTimeout()
            }
        }
    }
    
    private func handlePlaybackError(_ error: Error) {
        print("Playback error: \(error.localizedDescription)")
        playerObserver.playbackError = error
        playerObserver.isBuffering = false
        playerObserver.hasStartedPlaying = false
        
        // Attempt retry if we haven't exceeded max retries
        if connectionRetryCount < maxRetryCount {
            connectionRetryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.retryConnection()
            }
        }
    }
    
    private func handlePlaybackTimeout() {
        print("Playback timeout - stream failed to start")
        let timeoutError = NSError(domain: "LiveStreamError", code: -2, userInfo: [
            NSLocalizedDescriptionKey: "Stream connection timed out. Please check your network connection and try again."
        ])
        handlePlaybackError(timeoutError)
    }
    
    // MARK: - Control Actions
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
    }
    
    private func refreshStream() {
        playerObserver.hasStartedPlaying = false
        playerObserver.isBuffering = true
        connectionRetryCount = 0
        prepareStreamURL()
    }
    
    private func retryConnection() {
        print("Retrying connection (attempt \(connectionRetryCount + 1)/\(maxRetryCount))")
        playerObserver.playbackError = nil
        playerObserver.hasStartedPlaying = false
        playerObserver.isBuffering = true
        prepareStreamURL()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        
        // Clean up observer
        playerObserver.cleanupObservation()
        
        player = nil
        playerViewController = nil
        playerObserver.hasStartedPlaying = false
        playerObserver.isBuffering = false
        isPlayerReady = false
    }
}

// MARK: - Player View Controller Wrapper
struct PlayerViewControllerWrapper: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        return playerViewController
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}
