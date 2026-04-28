import SwiftUI

struct RestartOverlay: View {
    let targetLanguage: String
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.88

    private var languageLabel: String {
        targetLanguage.hasPrefix("en") ? "English" : "Deutsch"
    }

    private var flagEmoji: String {
        targetLanguage.hasPrefix("en") ? "🇬🇧" : "🇩🇪"
    }

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 18) {
                Text(flagEmoji)
                    .font(.system(size: 44))

                VStack(spacing: 6) {
                    Text(targetLanguage.hasPrefix("en")
                         ? "Switching to English"
                         : "Wechsel zu Deutsch")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(targetLanguage.hasPrefix("en")
                         ? "App is restarting…"
                         : "App wird neu gestartet…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ProgressView()
                    .scaleEffect(0.9)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                opacity = 1
                scale = 1
            }
        }
    }
}
