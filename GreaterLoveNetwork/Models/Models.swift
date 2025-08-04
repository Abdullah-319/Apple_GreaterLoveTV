import SwiftUI
import Foundation

// MARK: - Models
struct LiveStream: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let creation_time: String
    let embed_url: String?
    let hls_url: String?
    let thumbnail_url: String?
    let broadcasting_status: String?
    let ingest: Ingest?
    let playback: Playback?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, creation_time, embed_url, hls_url, thumbnail_url, broadcasting_status, ingest, playback
    }
}

struct Ingest: Codable {
    let server: String
    let key: String
}

struct Playback: Codable {
    let hls_url: String?
    let embed_url: String?
    let embed_audio_url: String?
}

struct Video: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let type: String
    let creation_time: String
    let data: [VideoData]
    let user: String
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, type, creation_time, data, user
    }
}

struct VideoData: Codable, Identifiable {
    let id = UUID()
    let dataId: String
    let fileName: String
    let enabled: Bool
    let bytes: Int
    let mediaInfo: MediaInfo?
    let encodingRequired: Bool
    let precedence: Int
    let author: String
    let creationTime: String
    let _id: String
    let playback: VideoPlayback?
    
    enum CodingKeys: String, CodingKey {
        case dataId = "id", fileName, enabled, bytes, mediaInfo, encodingRequired, precedence, author, creationTime, _id, playback
    }
}

struct MediaInfo: Codable {
    let hasAudioTrack: Bool
    let isVbr: Bool
    let duration: Int
    let width: Int
    let height: Int
    let fps: Int?
    let codecs: [Codec]
    let durationMins: Int
}

struct Codec: Codable {
    let type: String
    let codec: String
}

struct VideoPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
}

struct Recording: Codable, Identifiable {
    let id = UUID()
    let _id: String?
    let videoFolderId: String?
    let recordingId: String?
    let name: String
    let from: Int?
    let duration: Int?
    let bytes: Int?
    let status: String?
    let creationTime: String?
    let playback: RecordingPlayback?
    
    enum CodingKeys: String, CodingKey {
        case _id, videoFolderId, recordingId = "id", name, from, duration, bytes, status, creationTime, playback
    }
}

struct RecordingPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let color: Color
    let videos: [VideoData]
}

struct VideosResponse: Codable {
    let total: Int
    let page: Int
    let pages: Int
    let docs: [Video]
}

enum ThumbnailState: Equatable {
    case loading
    case loaded(UIImage)
    case failed
    
    static func == (lhs: ThumbnailState, rhs: ThumbnailState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.failed, .failed):
            return true
        case (.loaded(let lhsImage), (.loaded(let rhsImage))):
            return lhsImage.pngData() == rhsImage.pngData()
        default:
            return false
        }
    }
}
