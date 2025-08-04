import SwiftUI

// MARK: - Custom Video Control Components
struct VideoControlButton: View {
    let systemName: String
    var size: CGFloat = 50
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.6, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                )
                .scaleEffect(isFocused ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

struct ProgressSlider: View {
    @Binding var value: Double
    let maxValue: Double
    let onEditingChanged: (Bool) -> Void
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress track
                Rectangle()
                    .fill(Color.red)
                    .frame(width: progressWidth(geometry.size.width), height: 4)
                    .cornerRadius(2)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isFocused ? 16 : 12, height: isFocused ? 16 : 12)
                    .offset(x: progressWidth(geometry.size.width) - (isFocused ? 8 : 6))
                    .animation(.easeInOut(duration: 0.1), value: isFocused)
            }
        }
        .frame(height: 20)
        .focusable()
        .focused($isFocused)
        .onMoveCommand { direction in
            let step = maxValue / 100
            switch direction {
            case .left:
                value = max(0, value - step)
                onEditingChanged(false)
            case .right:
                value = min(maxValue, value + step)
                onEditingChanged(false)
            default:
                break
            }
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return totalWidth * CGFloat(value / maxValue)
    }
}
