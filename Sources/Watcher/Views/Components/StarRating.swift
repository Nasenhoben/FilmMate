import SwiftUI

struct StarRating: View {
    let rating: Double

    private var stars: Double { rating / 2.0 }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                starImage(for: index)
                    .font(.caption2)
                    .foregroundStyle(Color.yellow)
            }
            Text(String(format: "%.1f", rating))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if stars >= threshold + 1.0 {
            return Image(systemName: "star.fill")
        } else if stars >= threshold + 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}
