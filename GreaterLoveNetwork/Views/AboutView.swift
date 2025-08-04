import SwiftUI

// MARK: - About View
struct AboutView: View {
    @State private var showingQRCodes = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top Hero Section with Background Image
                topHeroSection
                
                // Main Content Section
                mainContentSection
                
                // Bottom Donation Section
                bottomDonationSection
            }
        }
        .background(Color.black.opacity(0.95))
        .sheet(isPresented: $showingQRCodes) {
            QRCodesView()
        }
    }
    
    private var topHeroSection: some View {
        HStack(spacing: 0) {
            // Left side - Title Text
            VStack(alignment: .leading, spacing: 20) {
                Text("ABOUT GREATER LOVE")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                
                Text("NETWORK TV")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            }
            .padding(.leading, 80)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side - Background image
            Image("about_us_top")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 600, height: 500)
                .clipped()
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .cornerRadius(12)
                .padding(.trailing, 80)
        }
        .frame(height: 500)
        .background(Color.black.opacity(0.95))
    }
    
    private var mainContentSection: some View {
        VStack(spacing: 80) {
            Spacer()
                .frame(height: 60)
            
            // Mission & Vision Section
            HStack(alignment: .top, spacing: 80) {
                // Left side - Text content
                VStack(alignment: .leading, spacing: 30) {
                    Text("OUR MISSION & VISION")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Greater Love Network Television has a singular goal; to reach souls with the good news of Jesus Christ.")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                    
                    Text("We seek out every available means of distribution to a world in need of hope. With an extensive blend of interdenominational and multi-cultural programming, we are committed to producing and providing quality television that will reach our viewers, refresh their lives, and renew their hearts.")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .lineSpacing(6)
                    
                    CTAButton(title: "CONTACT US") {
                        // Contact action
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side - Images (Horizontal arrangement)
                HStack(spacing: 20) {
                    Image("about_us_bottom_left")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 175, height: 220)
                        .cornerRadius(12)
                        .clipped()
                    
                    Image("about_us_bottom_right")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 175, height: 220)
                        .cornerRadius(12)
                        .clipped()
                }
            }
            .padding(.horizontal, 80)
        }
    }
    
    private var bottomDonationSection: some View {
        VStack(spacing: 60) {
            Spacer()
                .frame(height: 40)
            
            // Donation Content
            VStack(spacing: 40) {
                Text("DONATE NOW")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("HELP OTHERS STAND STRONG IN FAITH")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Around the world, and right where you live, people are desperate for something that will bring them peace, purpose, and a buffer from the confusion all around them. Of course, the only answer is Jesus. And here at Greater Love Network, through the partnership of friends like you, we're taking the message of His salvation and hope to millions every day.")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 120)
                
                // Greater Love Network Branding
                VStack(spacing: 25) {
                    HStack(spacing: 15) {
                        Text("GREATERLOVE")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .kerning(2)
                        
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 120, height: 2)
                        
                        Text("NETWORK")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .kerning(1.5)
                    }
                    
                    Text("THANK YOU FOR STANDING WITH US!")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    CTAButton(title: "DONATE NOW") {
                        showingQRCodes = true
                    }
                    .scaleEffect(1.1)
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 80)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 60)
            
            Spacer()
                .frame(height: 60)
        }
    }
}
