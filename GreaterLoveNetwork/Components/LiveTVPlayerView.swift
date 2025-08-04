import SwiftUI
import AVKit

// MARK: - Live TV Player
struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
               let url = URL(string: hlsURL) {
                VideoPlayer(player: player)
                    .onAppear {
                        setupPlayer(with: url)
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                    .overlay(
                        Group {
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
                        }
                    )
            } else {
                VStack(spacing: 40) {
                    Image(systemName: "tv.circle")
                        .font(.system(size: 120))
                        .foregroundColor(.red)
                    
                    Text(stream.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Live Stream")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if let status = stream.broadcasting_status {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(status == "online" ? Color.green : Color.red)
                                .frame(width: 16, height: 16)
                            
                            Text(status.capitalized)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            VStack {
                HStack {
                    CTAButton(title: "Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(stream.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let status = stream.broadcasting_status {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(status == "online" ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(status.uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(50)
        }
    }
    
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            isBuffering = true
        }
        
        playerTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                guard let item = self.player?.currentItem else { return }
                
                if item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = false
                } else if item.status == .readyToPlay && !item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = true
                }
            }
        }
        
        player?.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
    }
}
