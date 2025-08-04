import SwiftUI

// MARK: - Categories View
struct CategoriesView: View {
    @EnvironmentObject var apiService: CastrAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 80) {
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 60) {
                Text("ALL CATEGORIES")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                
                if apiService.isLoading || apiService.categories.isEmpty {
                    VStack(spacing: 50) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 50) {
                                ForEach(0..<4, id: \.self) { _ in
                                    LoadingCategoryCard()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50)
                    ], spacing: 50) {
                        ForEach(apiService.categories) { category in
                            CategoryDetailCard(category: category)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
        .background(Color.black.opacity(0.8))
    }
}
