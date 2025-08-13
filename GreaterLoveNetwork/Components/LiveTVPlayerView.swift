import SwiftUI
import AVKit

// MARK: - Enhanced Live TV Player with Immediate Playback
struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @State private var hasStartedPlaying = false
    @State private var streamURL: URL?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let streamURL = streamURL {
                VideoPlayer(player: player)
                    .onAppear {
                        if player == nil {
                            setupPlayerWithImediatePlayback(with: streamURL)
                        }
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                    .overlay(
                        Group {
                            if isBuffering && !hasStartedPlaying {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.8)
                                    
                                    Text("Connecting to live stream...")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.top, 10)
                                    
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .scaleEffect(1.5)
                                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                                        
                                        Text("LIVE")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.8))
                            }
                        }
                    )
            } else {
                // Loading or Error State
                VStack(spacing: 40) {
                    if isBuffering {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                            
                            Text("Preparing live stream...")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    } else {
                        Image(systemName: "tv.circle")
                            .font(.system(size: 120))
                            .foregroundColor(.red)
                        
                        Text("Stream Unavailable")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Unable to connect to the live stream")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Text(stream.name)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let status = stream.broadcasting_status {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(status == "online" ? Color.green : Color.red)
                                .frame(width: 16, height: 16)
                                .scaleEffect(status == "online" ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: status == "online")
                            
                            Text(status.capitalized)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            // Enhanced Control Overlay
            VStack {
                HStack {
                    CTAButton(title: "Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 12) {
                            Text(stream.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stream.broadcasting_status == "online" ? Color.red : Color.gray)
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(stream.broadcasting_status == "online" ? 1.3 : 1.0)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: stream.broadcasting_status == "online")
                                
                                Text("LIVE")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(stream.broadcasting_status == "online" ? .red : .gray)
                            }
                        }
                        
                        if hasStartedPlaying {
                            Text("Broadcasting live")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        } else if isBuffering {
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
                
                Spacer()
            }
            .padding(50)
        }
        .onAppear {
            prepareStreamURL()
        }
    }
    
    private func prepareStreamURL() {
        isBuffering = true
        
        // Try different URL sources in order of preference
        if let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
           let url = URL(string: hlsURL) {
            streamURL = url
            return
        }
        
        if let embedURL = stream.embed_url ?? stream.playback?.embed_url,
           let url = URL(string: embedURL) {
            streamURL = url
            return
        }
        
        // If no valid URL found, stop loading
        isBuffering = false
    }
    
    private func setupPlayerWithImediatePlayback(with url: URL) {
        // Create player with optimized settings for live streaming
        let playerItem = AVPlayerItem(url: url)
        
        // Configure for live streaming - prefer low latency
        if #available(iOS 14.0, *) {
            playerItem.preferredForwardBufferDuration = 2.0 // Minimal buffer for live
        }
        
        player = AVPlayer(playerItem: playerItem)
        
        // Configure player for immediate playback
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.allowsExternalPlayback = true
        
        // Setup observers
        setupPlayerObservers(for: playerItem)
        
        // Start playing immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.player?.play()
        }
    }
    
    private func setupPlayerObservers(for playerItem: AVPlayerItem) {
        // Observe buffering state changes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            self.isBuffering = true
            print("Live stream stalled - rebuffering...")
        }
        
        // Observe when player is ready to play
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            if !self.hasStartedPlaying {
                self.isBuffering = false
                self.hasStartedPlaying = true
                print("Live stream started successfully")
            }
        }
        
        // Monitor playback status - FIXED: Removed [weak self]
        playerTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { _ in
            guard let player = self.player else { return }
            
            DispatchQueue.main.async {
                if let item = player.currentItem {
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
                        print("Live stream failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
        hasStartedPlaying = false
        isBuffering = false
    }
}
