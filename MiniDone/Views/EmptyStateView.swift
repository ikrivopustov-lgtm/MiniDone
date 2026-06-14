import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(AppStyle.mutedText)

            Text(title)
                .font(AppStyle.font(13, .medium))
                .foregroundStyle(AppStyle.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
