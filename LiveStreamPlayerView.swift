//import SwiftUI
//import AVKit
//
//// MARK: - Live Stream Player View
//struct LiveStreamPlayerView: View {
//    let stream: LiveStream
//    @Environment(\.presentationMode) var presentationMode
//    @State private var showingControls = true
//    
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Header with controls
//                if showingControls {
//                    HStack {
//                        Button("← Back") {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 25)
//                        .padding(.vertical, 12)
//                        .background(Color.black.opacity(0.8))
//                        .cornerRadius(8)
//                        .buttonStyle(PlainButtonStyle())
//                        
//                        Spacer()
//                        
//                        VStack(alignment: .trailing, spacing: 4) {
//                            Text(stream.name)
//                                .font(.system(size: 18, weight: .semibold))
//                                .foregroundColor(.white)
//                                .lineLimit(1)
//                            
//                            HStack(spacing: 8) {
//                                Circle()
//                                    .fill(stream.broadcasting_status == "online" ? Color.green : Color.red)
//                                    .frame(width: 8, height: 8)
//                                
//                                Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
//                                    .font(.system(size: 12, weight: .semibold))
//                                    .foregroundColor(.white)
//                            }
//                        }
//                        .padding(.horizontal, 25)
//                        .padding(.vertical, 12)
//                        .background(Color.black.opacity(0.8))
//                        .cornerRadius(8)
//                    }
//                    .padding(.horizontal, 30)
//                    .padding(.top, 50)
//                    .zIndex(1)
//                }
//                
//                // Live Stream Player Area
//                VStack(spacing: 0) {
//                    Spacer()
//                    
//                    Group {
//                        
//                        Rectangle()
//                            .fill(
//                                LinearGradient(
//                                    colors: [
//                                        Color.red.opacity(0.4),
//                                        Color.orange.opacity(0.3)
//                                    ],
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                )
//                            )
//                            .frame(height: 400)
//                            .overlay(
//                                VStack(spacing: 20) {
//                                    Image(systemName: "dot.radiowaves.left.and.right")
//                                        .font(.system(size: 80))
//                                        .foregroundColor(.white)
//                                    
//                                    Text("LIVE STREAM")
//                                        .font(.system(size: 24, weight: .bold))
//                                        .foregroundColor(.white)
//                                    
//                                    Text(stream.name)
//                                        .font(.system(size: 18, weight: .medium))
//                                        .foregroundColor(.white.opacity(0.8))
//                                        .multilineTextAlignment(.center)
//                                        .lineLimit(2)
//                                    
//                                    HStack(spacing: 8) {
//                                        Circle()
//                                            .fill(stream.broadcasting_status == "online" ? Color.green : Color.red)
//                                            .frame(width: 12, height: 12)
//                                        
//                                        Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
//                                            .font(.system(size: 14, weight: .semibold))
//                                            .foregroundColor(.white)
//                                    }
//                                }
//                            )
//                            .cornerRadius(16)
//                    }
//                }
//                .padding(.horizontal, 30)
//                .onTapGesture {
//                    withAnimation(.easeInOut(duration: 0.3)) {
//                        showingControls.toggle()
//                    }
//                }
//                
//                Spacer()
//                
//                // Bottom controls
//                if showingControls {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text(stream.name)
//                                .font(.system(size: 20, weight: .bold))
//                                .foregroundColor(.white)
//                                .lineLimit(2)
//                            
//                            HStack(spacing: 15) {
//                                Label("Live Stream", systemImage: "dot.radiowaves.left.and.right")
//                                    .font(.system(size: 14, weight: .medium))
//                                    .foregroundColor(.gray)
//                                
//                                HStack(spacing: 6) {
//                                    Circle()
//                                        .fill(stream.broadcasting_status == "online" ? Color.green : Color.red)
//                                        .frame(width: 8, height: 8)
//                                    
//                                    Text(stream.broadcasting_status?.capitalized ?? "Offline")
//                                        .font(.system(size: 14, weight: .medium))
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                        }
//                        
//                        Spacer()
//                        
//                        // Action buttons
//                        HStack(spacing: 15) {
//#if os(iOS)
//                            if let embedUrl = stream.embed_url ?? stream.playback?.embed_url {
//                                Button(action: {
//                                    openInBrowser(url: embedUrl)
//                                }) {
//                                    Image(systemName: "safari")
//                                        .font(.system(size: 20))
//                                        .foregroundColor(.white)
//                                }
//                                .padding(12)
//                                .background(Color.red.opacity(0.8))
//                                .cornerRadius(8)
//                            }
//#else
//                            // For tvOS, show info button
//                            if let embedUrl = stream.embed_url ?? stream.playback?.embed_url {
//                                Button(action: {
//                                    print("Stream URL: \(embedUrl)")
//                                }) {
//                                    Image(systemName: "info.circle")
//                                        .font(.system(size: 20))
//                                        .foregroundColor(.white)
//                                }
//                                .padding(12)
//                                .background(Color.red.opacity(0.8))
//                                .cornerRadius(8)
//                            }
//#endif
//                        }
//                    }
//                    .padding(.horizontal, 30)
//                    .padding(.bottom, 50)
//                }
//            }
//            
//            .onAppear {
//                print("Opening live stream player for: \(stream.name)")
//                if let embedUrl = stream.embed_url ?? stream.playback?.embed_url {
//                    print("Stream embed URL: \(embedUrl)")
//                }
//            }
//            .onTapGesture {
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    showingControls.toggle()
//                }
//            }
//        }
//    }
//}
