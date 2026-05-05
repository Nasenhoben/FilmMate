import SwiftUI

// Compact dot-badge for movie cards
struct ProviderDot: View {
    let provider: StreamingProvider

    var body: some View {
        Text(provider.shortLabel)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(provider.color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// Full row for sidebar
struct ProviderRow: View {
    let provider: StreamingProvider
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(provider.color)
                .frame(width: 3, height: 28)

            Text(provider.name)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(provider.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? provider.color.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

extension StreamingProvider {
    var shortLabel: String {
        switch self {
        case .netflix:       return "N"
        case .amazonPrime:   return "P"
        case .disneyPlus:    return "D+"
        case .hboMax:        return "HBO"
        case .paramountPlus: return "P+"
        case .crunchyroll:   return "CR"
        case .appleTVPlus:   return "TV+"
        case .sky:           return "SK"
        case .joyn:          return "J"
        case .rtlPlus:       return "R+"
        case .magentaTV:     return "MT"
        case .wow:           return "W"
        case .plutoTV:       return "PL"
        case .rakutenTV:     return "RT"
        case .ard:           return "A"
        case .zdf:           return "Z"
        case .arte:          return "ar"
        case .netzkino:      return "NK"
        case .maxdome:       return "MX"
        }
    }
}
