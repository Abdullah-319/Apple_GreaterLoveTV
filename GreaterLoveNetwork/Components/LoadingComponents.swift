import SwiftUI

// MARK: - Loading Components
struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 300, height: 170)
                .cornerRadius(12)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 20)
                .cornerRadius(4)
        }
    }
}

struct LoadingCategoryCard: View {
    var body: some View {
        VStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 280, height: 158)
                .cornerRadius(8)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 16)
                .cornerRadius(4)
        }
    }
}

struct LoadingShowCard: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 140, height: 140)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            VStack(spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                    .cornerRadius(4)
            }
        }
    }
}

struct LoadingLiveStreamCard: View {
    let number: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 25) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 440, height: 248)
                .overlay(
                    VStack(spacing: 10) {
                        Text("GREATER LOVE TV")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(number)
                            .font(.system(size: 96, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                )
                .cornerRadius(12)
            
            Text(subtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
