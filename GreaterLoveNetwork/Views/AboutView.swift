import SwiftUI

// MARK: - About View
struct AboutView: View {
    @State private var showingQRCodes = false
    
    // FIX: Define explicit identifiers for the focusable items.
    // We use an enum for better type safety instead of raw strings.
    enum FocusableField: Hashable {
        case contact
        case donate
    }
    
    // FIX: Use the enum for our FocusState variable.
    @FocusState private var focusedField: FocusableField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                topHeroSection
                mainContentSection
                bottomDonationSection
            }
            // FIX: Add a handler for directional navigation (arrow keys/remote swipes).
            // This tells SwiftUI exactly how to move the focus between buttons.
            .onMoveCommand(perform: handleMoveCommand)
        }
        .background(Color.black.opacity(0.95))
        .ignoresSafeArea(.all)
        // FIX: Set the initial focus to the "CONTACT US" button when the view appears.
        .onAppear {
            focusedField = .contact
        }
        .sheet(isPresented: $showingQRCodes) {
            QRCodesView()
        }
    }
    
    // FIX: A function to handle the up/down navigation logic.
    private func handleMoveCommand(direction: MoveCommandDirection) {
        // We only care about up and down movements.
        guard direction == .up || direction == .down else { return }

        // Logic for moving downwards
        if direction == .down {
            if focusedField == .contact {
                focusedField = .donate // Move from Contact Us down to Donate Now
            }
        }
        
        // Logic for moving upwards
        if direction == .up {
            if focusedField == .donate {
                focusedField = .contact // Move from Donate Now up to Contact Us
            }
        }
    }

    private var topHeroSection: some View {
        ZStack {
            Image("about_us_top")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 540)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .black.opacity(0.3), .black.opacity(0.6)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ABOUT GREATER LOVE")
                        .font(.system(size: 64, weight: .bold))
                    Text("NETWORK TV")
                        .font(.system(size: 64, weight: .bold))
                        .padding(.top, -10)
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
                .kerning(-1)
                .padding(.leading, 80)
                
                Spacer()
            }
        }
    }
    
    private var mainContentSection: some View {
        HStack(alignment: .top, spacing: 60) {
            VStack(alignment: .leading, spacing: 30) {
                Text("OUR MISSION & VISION")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 80)
                
                Text("Greater Love Network Television Network has a singular goal; to reach souls with the good news of Jesus Christ.")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(8)
                
                Text("We seek out every available means of distribution to a world in need of hope. With an extensive blend of interdenominational and multi-cultural programming, Daystar is committed to producing and providing quality television that will reach our viewers, refresh their lives, and renew their hearts.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .lineSpacing(6)
                    .padding(.top, 10)
                
                Button(action: { /* Contact action */ }) {
                    Text("CONTACT US")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.85, green: 0.2, blue: 0.2)))
                        // FIX: Use scaleEffect to visually show focus.
                        .scaleEffect(focusedField == .contact ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                // FIX: Attach the focus state to the button using the .contact case.
                .focused($focusedField, equals: .contact)
                .animation(.easeInOut(duration: 0.1), value: focusedField)
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 80)
            
            HStack(spacing: 20) {
                Image("about_us_bottom_left").resizable().aspectRatio(contentMode: .fill)
                Image("about_us_bottom_right").resizable().aspectRatio(contentMode: .fill)
            }
            .frame(width: 420, height: 350)
            .cornerRadius(12)
            .clipped()
            .padding(.trailing, 80)
            .padding(.top, 80)
        }
        .padding(.bottom, 100)
    }
    
    private var bottomDonationSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                Text("DONATE NOW")
                    .font(.system(size: 24, weight: .bold))
                Text("HELP OTHERS STAND STRONG IN FAITH")
                    .font(.system(size: 48, weight: .bold))
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 60)
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            Text("Around the world, and right where you live, people are desperate for something that will bring them peace... Your generous gift will help us send out life-transforming content designed to communicate the good news of Jesus and strengthen faith.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 120)
                .padding(.bottom, 60)
            
            VStack(spacing: 30) {
                HStack(spacing: 20) {
                    Text("GREATERLOVE").font(.system(size: 18, weight: .bold))
                    Rectangle().fill(Color.white).frame(width: 100, height: 2)
                    Text("NETWORK").font(.system(size: 10, weight: .medium))
                }.foregroundColor(.white)
                
                Text("THANK YOU FOR STANDING WITH US!").font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Button(action: { showingQRCodes = true }) {
                    Text("DONATE NOW")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 0.85, green: 0.2, blue: 0.2)))
                        // FIX: Use scaleEffect to visually show focus.
                        .scaleEffect(focusedField == .donate ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                // FIX: Attach the focus state to the button using the .donate case.
                .focused($focusedField, equals: .donate)
                .animation(.easeInOut(duration: 0.1), value: focusedField)
            }
            .padding(.bottom, 80)
        }
    }
}
