import SwiftUI

// MARK: - Navigation Bar with Enhanced Focus Management
struct NavigationBar: View {
    @Binding var selectedItem: String
    
    private let navItems = ["HOME", "ABOUT US", "ALL SHOWS", "INFO"]
    @FocusState var focusedItem: String?
    @State private var shouldMaintainFocus = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image("tv_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.leading, 60)
            
            Spacer()
            
            HStack(spacing: 80) {
                ForEach(navItems, id: \.self) { item in
                    NavigationBarButton(
                        title: item,
                        isSelected: selectedItem == item,
                        isFocused: focusedItem == item
                    ) {
                        // When button is pressed, change page but maintain focus on navigation
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedItem = item
                            shouldMaintainFocus = true
                        }
                    }
                    .focused($focusedItem, equals: item)
                }
            }
            .padding(.trailing, 60)
            
            Spacer()
        }
        .padding(.vertical, 25)
        .background(Color.black.opacity(0.95))
        .zIndex(1)
        .onChange(of: focusedItem) { newFocusedItem in
            // Only navigate when focus changes via remote control (not button press)
            if let newItem = newFocusedItem, newItem != selectedItem && !shouldMaintainFocus {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedItem = newItem
                }
            }
            // Reset the maintain focus flag after processing
            if shouldMaintainFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    shouldMaintainFocus = false
                }
            }
        }
        .onAppear {
            // Set initial focus to the selected item
            if focusedItem == nil {
                focusedItem = selectedItem
            }
        }
        .onMoveCommand { direction in
            // Handle navigation movement but keep focus within navigation
            switch direction {
            case .left:
                if let currentIndex = navItems.firstIndex(of: focusedItem ?? selectedItem),
                   currentIndex > 0 {
                    focusedItem = navItems[currentIndex - 1]
                }
            case .right:
                if let currentIndex = navItems.firstIndex(of: focusedItem ?? selectedItem),
                   currentIndex < navItems.count - 1 {
                    focusedItem = navItems[currentIndex + 1]
                }
            case .down:
                // Only move focus down to content when explicitly pressing down
                // The content view will handle receiving focus
                break
            default:
                break
            }
        }
    }
}

// MARK: - Navigation Bar Button
struct NavigationBarButton: View {
    let title: String
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .kerning(0.5)
                
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
