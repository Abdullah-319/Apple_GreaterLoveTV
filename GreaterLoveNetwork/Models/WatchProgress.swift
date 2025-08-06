import Foundation

// MARK: - Watch Progress Model
struct WatchProgress: Codable, Identifiable {
    let id = UUID()
    let videoId: String
    let videoTitle: String
    let currentTime: Double
    let duration: Double
    let progressPercentage: Double
    let lastWatched: Date
    
    enum CodingKeys: String, CodingKey {
        case videoId, videoTitle, currentTime, duration, progressPercentage, lastWatched
    }
    
    init(videoId: String, videoTitle: String, currentTime: Double, duration: Double, progressPercentage: Double, lastWatched: Date) {
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.currentTime = currentTime
        self.duration = duration
        self.progressPercentage = progressPercentage
        self.lastWatched = lastWatched
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoId = try container.decode(String.self, forKey: .videoId)
        videoTitle = try container.decode(String.self, forKey: .videoTitle)
        currentTime = try container.decode(Double.self, forKey: .currentTime)
        duration = try container.decode(Double.self, forKey: .duration)
        progressPercentage = try container.decode(Double.self, forKey: .progressPercentage)
        lastWatched = try container.decode(Date.self, forKey: .lastWatched)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoId, forKey: .videoId)
        try container.encode(videoTitle, forKey: .videoTitle)
        try container.encode(currentTime, forKey: .currentTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(progressPercentage, forKey: .progressPercentage)
        try container.encode(lastWatched, forKey: .lastWatched)
    }
    
    // Helper computed properties
    var formattedCurrentTime: String {
        return formatTime(currentTime)
    }
    
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    var remainingTime: Double {
        return max(0, duration - currentTime)
    }
    
    var formattedRemainingTime: String {
        return formatTime(remainingTime)
    }
    
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
