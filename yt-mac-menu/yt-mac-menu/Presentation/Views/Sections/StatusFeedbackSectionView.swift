import SwiftUI

struct StatusFeedbackSectionView: View {
    
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    
    init(title: String, subtitle: String = "", iconName: String, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 80))
                .foregroundColor(color)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .transition(.opacity)
    }
}
