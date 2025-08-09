import SwiftUI

// MARK: - QR Codes View
struct QRCodesView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 60) {
                    // Header
                    VStack(spacing: 20) {
                        HStack {
                            CTAButton(title: "Back") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 80)
                        .padding(.top, 40)
                        
                        Text("GREATERLOVE")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(2)
                        
                        Text("NETWORK")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .kerning(1.5)
                    }
                    
                    // QR Codes Grid
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

// MARK: - QR Code Card
struct QRCodeCard: View {
    let title: String
    let imageName: String
    @FocusState private var isFocused: Bool
    
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
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(color: .white.opacity(isFocused ? 0.3 : 0.1), radius: isFocused ? 10 : 5)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .focusable()
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
