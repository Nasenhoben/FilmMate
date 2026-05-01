import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsViewModel
    @ObservedObject var vm: MovieViewModel
    @State private var apiKeyVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // API Key card
                settingsCard {
                    cardHeader(icon: "key.fill", color: .orange, title: "TMDB API-Key")

                    // Input row
                    HStack(spacing: 8) {
                        // Status icon
                        if settings.isValidating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: settings.apiKeyState.icon)
                                .font(.callout)
                                .foregroundStyle(settings.apiKeyState.color)
                                .animation(.spring(duration: 0.2), value: settings.apiKeyState)
                        }

                        if apiKeyVisible {
                            TextField(String(localized: "settings.api_key.placeholder"), text: $settings.apiKey)
                                .textFieldStyle(.plain)
                                .font(.callout)
                        } else {
                            SecureField(String(localized: "settings.api_key.placeholder"), text: $settings.apiKey)
                                .textFieldStyle(.plain)
                                .font(.callout)
                        }

                        Button {
                            apiKeyVisible.toggle()
                        } label: {
                            Image(systemName: apiKeyVisible ? "eye.slash" : "eye")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(settings.apiKeyState.color.opacity(
                                settings.apiKeyState == .unchecked ? 0 : 0.5
                            ), lineWidth: 1.5)
                    )

                    // Validate button + status message
                    HStack {
                        if let message = settings.apiKeyState.message {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                Text(message)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.red)
                            .transition(.opacity)
                        } else if settings.apiKeyState == .valid {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text(String(localized: "settings.api_key.valid"))
                                    .font(.caption2)
                            }
                            .foregroundStyle(.green)
                            .transition(.opacity)
                        } else if settings.apiKey.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                Text("themoviedb.org/settings/api")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            Task { await settings.validateAPIKey() }
                        } label: {
                            HStack(spacing: 5) {
                                if settings.isValidating {
                                    ProgressView().scaleEffect(0.65)
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text(String(localized: "settings.api_key.validate"))
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.12))
                            .foregroundStyle(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(settings.apiKey.isEmpty || settings.isValidating)
                    }
                    .animation(.easeInOut(duration: 0.2), value: settings.apiKeyState)
                }

                // Appearance card
                settingsCard {
                    cardHeader(icon: "paintbrush.fill", color: .purple, title: String(localized: "settings.section.appearance"))

                    settingsRow(label: String(localized: "settings.theme"), icon: "circle.lefthalf.filled") {
                        HStack(spacing: 6) {
                            ForEach(ColorSchemePreference.allCases, id: \.self) { scheme in
                                Button {
                                    settings.colorSchemePreference = scheme
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: scheme.icon)
                                            .font(.caption2)
                                        Text(scheme.localizedName)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(
                                        settings.colorSchemePreference == scheme
                                            ? Color.accentColor
                                            : Color.primary.opacity(0.07)
                                    )
                                    .foregroundStyle(
                                        settings.colorSchemePreference == scheme ? Color.white : Color.primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Database card
                settingsCard {
                    cardHeader(icon: "cylinder.fill", color: .blue, title: String(localized: "settings.section.database"))

                    // Status row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let date = vm.lastUpdated {
                                Text(String(localized: "settings.database"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Text(date, style: .date)
                                    Text("·")
                                    Text(date, style: .time)
                                }
                                .font(.caption)
                                .foregroundStyle(.primary)
                            } else {
                                Text(String(localized: "settings.database.never"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if DatabaseService.shared.totalCount > 0 {
                            Text("\(DatabaseService.shared.totalCount) \(String(localized: "settings.database.movies"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    // Progress
                    if vm.isUpdating {
                        VStack(alignment: .leading, spacing: 6) {
                            ProgressView(value: vm.updateProgress)
                                .progressViewStyle(.linear)
                                .tint(Color.blue)

                            HStack {
                                Text(vm.updateStatusText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f%%", vm.updateProgress * 100))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    } else if vm.updateComplete {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.callout)
                            Text(String(localized: "settings.database.updated"))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }

                    // Update button
                    Button {
                        Task { await vm.updateDatabase() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.callout)
                            Text(vm.isUpdating
                                 ? String(localized: "settings.database.updating")
                                 : String(localized: "settings.database.update"))
                                .font(.callout)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(settings.apiKey.isEmpty
                                    ? Color.secondary.opacity(0.15)
                                    : Color.blue)
                        .foregroundStyle(settings.apiKey.isEmpty ? Color.secondary : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isUpdating || settings.apiKey.isEmpty)
                    .padding(.top, 4)
                }
            }
            .padding(20)
        }
        .frame(width: 460)
        .alert(String(localized: "error.title"), isPresented: $vm.showUpdateError) {
            Button(String(localized: "button.ok")) { vm.showUpdateError = false }
        } message: {
            Text(vm.updateError ?? "")
        }
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(16)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }

    private func cardHeader(icon: String, color: Color, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
        }
    }

    private func settingsRow<Control: View>(
        label: String,
        icon: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(label)
                    .font(.callout)
            }
            Spacer()
            control()
        }
    }
}
