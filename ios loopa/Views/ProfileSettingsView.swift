//
//  ProfileSettingsView.swift
//  ios loopa
//
//  Created by Codex on 2026-02-04.
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = "Thomas"
    @State private var introduction: String = ""
    @State private var instagramUsername: String = ""
    @State private var tiktokUsername: String = ""
    @State private var dateOfBirth: Date = Date(timeIntervalSince1970: 1013904000) // Feb 17, 2002
    @State private var genderPreference: String = "Everyone"
    @State private var nationality: String = "France"
    @State private var selectedLifestyle: String = "digital nomad"

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    profilePicturesSection
                    textFieldSection(title: "First Name", placeholder: "Thomas", text: $firstName)
                    introSection
                    dateFieldSection
                    genderPreferenceSection
                    travelLifestyleSection
                    textFieldSection(title: "Instagram Username", placeholder: "Instagram username", text: $instagramUsername)
                    textFieldSection(title: "TikTok Username", placeholder: "TikTok username", text: $tiktokUsername)
                    nationalitySection
                    languagesSection
                    interestsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Update")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.appAccent, in: Capsule())
                }
            }
            Text("Edit Profile")
                .font(.app(size: 26, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var profilePicturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Pictures")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)

            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack {
                    Text("Main Picture")
                        .font(.app(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "camera")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            HStack(spacing: 12) {
                secondaryPictureCard(title: "2nd Pic")
                secondaryPictureCard(title: "3rd Pic")
            }
        }
    }

    private func secondaryPictureCard(title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray5))
                .frame(height: 120)

            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text(title)
                    .font(.app(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "camera")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func textFieldSection(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            TextField(placeholder, text: text)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Introduction")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            TextEditor(text: $introduction)
                .frame(height: 120)
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if introduction.isEmpty {
                        Text("Write something...")
                            .font(.app(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                }
                .scrollContentBackground(.hidden)
        }
    }

    private var dateFieldSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date of Birth")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            ZStack {
                HStack {
                    Text(dateOfBirth.formatted(date: .long, time: .omitted))
                        .font(.app(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .opacity(0.02)
                    .padding(.horizontal, 16)
            }
        }
    }

    private var genderPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender Preference")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            Text("You'll only receive messages from this gender")
                .font(.app(size: 13, weight: .regular))
                .foregroundStyle(.secondary)

            Menu {
                Button("🧑‍🤝‍🧑 Everyone") { genderPreference = "Everyone" }
                Button("👩 Women") { genderPreference = "Women" }
                Button("👨 Men") { genderPreference = "Men" }
                Button("⚧️ Non-binary") { genderPreference = "Non-binary" }
            } label: {
                HStack {
                    Text(genderPreferenceEmoji)
                    Text(genderPreference)
                        .font(.app(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var travelLifestyleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Travel Lifestyle")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)

            Menu {
                ForEach(lifestyleOptions, id: \.id) { option in
                    Button("\(option.emoji) \(option.label)") {
                        selectedLifestyle = option.id
                    }
                }
            } label: {
                HStack {
                    Text(lifestyleEmoji(for: selectedLifestyle))
                    Text(selectedLifestyle)
                        .font(.app(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var nationalitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nationality")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            Menu {
                Button("🇫🇷 France") { nationality = "France" }
                Button("🇨🇦 Canada") { nationality = "Canada" }
                Button("🇺🇸 USA") { nationality = "USA" }
                Button("🇧🇷 Brazil") { nationality = "Brazil" }
            } label: {
                HStack {
                    Text(nationalityFlag)
                    Text(nationality)
                        .font(.app(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Languages")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            HStack(spacing: 12) {
                tagChip("English")
                tagChip("French")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests")
                .font(.app(size: 17, weight: .bold))
                .foregroundStyle(.black)
            HStack(spacing: 12) {
                tagChip("🏂 Adventure Travel")
                tagChip("🎨 Art & Culture")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.app(size: 14, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white, in: Capsule())
    }

    private var lifestyleOptions: [LifestyleOption] {
        [
            LifestyleOption(id: "backpacking", emoji: "🎒", label: "backpacking"),
            LifestyleOption(id: "digital nomad", emoji: "💻", label: "digital nomad"),
            LifestyleOption(id: "gap year", emoji: "👋", label: "gap year"),
            LifestyleOption(id: "studying abroad", emoji: "📚", label: "studying abroad"),
            LifestyleOption(id: "living abroad", emoji: "🏠", label: "living abroad"),
            LifestyleOption(id: "au pair", emoji: "🤹", label: "au pair")
        ]
    }

    private func lifestyleEmoji(for id: String) -> String {
        lifestyleOptions.first(where: { $0.id == id })?.emoji ?? "🎒"
    }

    private var genderPreferenceEmoji: String {
        switch genderPreference {
        case "Women": return "👩"
        case "Men": return "👨"
        case "Non-binary": return "⚧️"
        default: return "🧑‍🤝‍🧑"
        }
    }

    private var nationalityFlag: String {
        switch nationality.lowercased() {
        case "france": return "🇫🇷"
        case "canada": return "🇨🇦"
        case "usa": return "🇺🇸"
        case "brazil": return "🇧🇷"
        default: return "🏳️"
        }
    }
}

private struct LifestyleOption {
    let id: String
    let emoji: String
    let label: String
}
