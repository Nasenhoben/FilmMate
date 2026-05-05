import SwiftUI

struct GenreChip: View {
    let genre: Genre
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Text(genre.emoji)
                .font(.system(size: 13))
            Text(genre.localizedName)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            isSelected
                ? genre.color
                : genre.color.opacity(0.12)
        )
        .foregroundStyle(isSelected ? Color.white : genre.color)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(genre.color.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
        )
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
