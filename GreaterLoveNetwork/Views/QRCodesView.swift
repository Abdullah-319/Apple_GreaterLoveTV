import SwiftUI

// MARK: - QR Codes View
struct QRCodesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 60) {
                    // Header - No Back button
                    VStack(spacing: 10) {
                     
                    }
                    
                    // QR Codes Grid - Non-focusable
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 60),
                        GridItem(.flexible(), spacing: 60)
                    ], spacing: 60) {
                        QRCodeCard(
                            title: "Donate",
                            imageName: "donate_qrcode"
                        )
                        
                        QRCodeCard(
                            title: "Tell Your Story",
                            imageName: "tell_your_story_qrcode"
                        )
                        
                        QRCodeCard(
                            title: "Prayer Request",
                            imageName: "prayer_request_qrcode"
                        )
                        
                        QRCodeCard(
                            title: "Download Mobile App",
                            imageName: "download_mobile_app_qrcode"
                        )
                    }
                    .padding(.horizontal, 80)
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
        }
    }
}

// MARK: - QR Code Card - Non-focusable
struct QRCodeCard: View {
    let title: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Rectangle()
                .fill(Color.white)
                .frame(width: 250, height: 250)
                .overlay(
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 280, height: 280)
                )
                .cornerRadius(16)
                .shadow(color: .white.opacity(0.1), radius: 5)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        // Removed .focusable() and @FocusState to make it non-interactive
    }
}
