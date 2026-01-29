//
//  ProfileView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import UIKit

struct ProfileView: View {
    let user: User
    let onBack: () -> Void
    let onMessage: (User) -> Void

    private let age = 21
    private let location = "CANADA"
    @State private var showPhotoViewer = false
    @State private var showMoreActions = false
    @State private var showBlockConfirm = false
    @State private var showReportConfirm = false
    private var aboutText: String {
        "Hey, I'm \(user.name)! I love meeting travelers nearby. Say hi and share your next destination ✨"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                heroSection(in: geometry)

                VStack {
                    Spacer()
                    floatingCard(in: geometry)
                }
            }
            .background(Color.black.opacity(0.001))
            .alert("Block \(user.name)?", isPresented: $showBlockConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Block", role: .destructive) {}
            } message: {
                Text("You will no longer see this user or their content.")
            }
            .alert("Report \(user.name)?", isPresented: $showReportConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Report", role: .destructive) {}
            } message: {
                Text("Thanks for helping keep the community safe.")
            }
            .fullScreenCover(isPresented: $showPhotoViewer) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    userImageView(user, contentMode: .fit)
                        .padding(.horizontal, 0)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: { showPhotoViewer = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
                .onTapGesture {
                    showPhotoViewer = false
                }
            }
        }
    }

    private func heroSection(in geometry: GeometryProxy) -> some View {
        let heroHeight = geometry.size.height * 0.52
        let heroCornerRadius: CGFloat = 24

        return ZStack(alignment: .top) {
            userImageView(user, contentMode: .fill)
                .frame(width: geometry.size.width, height: heroHeight, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    showPhotoViewer = true
                }

            LinearGradient(
                colors: [.clear, .black.opacity(0.4)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: geometry.size.width, height: heroHeight)
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))

            VStack {
                HStack {
                    CircleIconButton(systemName: "arrow.left", action: onBack)
                    Spacer()
                    CircleIconButton(systemName: "ellipsis") {
                        showMoreActions = true
                    }
                    .popover(isPresented: $showMoreActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        moreActionsPopover
                            .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 2)

                Spacer()

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(user.name), \(age)")
                            .font(.app(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)

                        ZStack {
                            Circle()
                                .fill(Color.blue)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 22, height: 22)
                    }

                    HStack(spacing: 6) {
                        Text(user.flag)
                            .font(.app(size: 18))
                        Text(location)
                            .font(.app(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }


                }
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity)
            }
            .frame(width: geometry.size.width, height: heroHeight)
        }
        .frame(width: geometry.size.width, height: heroHeight)
        .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))
        .ignoresSafeArea(.container, edges: .top)
    }

    private var moreActionsPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                showMoreActions = false
                showBlockConfirm = true
            }) {
                Label("Block User", systemImage: "hand.raised.fill")
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)

            Divider()

            Button(action: {
                showMoreActions = false
                showReportConfirm = true
            }) {
                Label("Report User", systemImage: "exclamationmark.bubble.fill")
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }

    private func floatingCard(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 12) {
                            CompactPillButton(
                                icon: "person.badge.plus",
                                text: "Add Friend",
                                style: .accent
                            ) {}
                            CompactPillButton(icon: "bubble.left", text: "Message") {
                                onMessage(user)
                            }
                        }
                        Spacer(minLength: 0)
                    }

                    sectionDivider

                    section(title: "About Me", systemImage: "person.text.rectangle") {
                        Text(aboutText)
                            .font(.app(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }

                    if let lifestyle = user.lifestyle, !lifestyle.isEmpty {
                        sectionDivider
                        section(title: "Lifestyle", systemImage: "sparkles") {
                            lifestyleChip(text: lifestyle)
                        }
                    }

                    sectionDivider

                    section(title: "Badges", systemImage: "checkmark.seal") {
                        badgeChip(title: "Verified", systemImage: "checkmark")
                    }

                    sectionDivider

                    section(title: "Upcoming Trips", systemImage: "airplane") {
                        tripCard(
                            flag: "🇵🇹",
                            destination: "Lisbon",
                            dates: "4 Mar - 16 Mar, 2026"
                        )
                    }

                    sectionDivider

                    section(title: "Interests", systemImage: "sparkles") {
                        FlowLayout(spacing: 8) {
                            interestTag(icon: "bag.fill", text: "Fashion & Shopping", color: .pink)
                            interestTag(icon: "building.2.fill", text: "Nightlife", color: .blue)
                            interestTag(icon: "tent.fill", text: "Off-Grid Spots", color: .orange)
                        }
                    }
                }
                .padding(.top, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(width: geometry.size.width - 32)
        .frame(maxHeight: geometry.size.height * 0.5)
        .padding(.bottom, max(4, geometry.safeAreaInsets.bottom))
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.secondary.opacity(0.2))
    }

    private func section<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            content()
        }
    }

    private func badgeChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 20, height: 20)

            Text(title)
                .font(.app(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    private func tripCard(flag: String, destination: String, dates: String) -> some View {
        HStack(spacing: 12) {
            Text(flag)
                .font(.app(size: 26))
                .frame(width: 52, height: 52)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(destination)
                    .font(.app(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text(dates)
                    .font(.app(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    private func lifestyleChip(text: String) -> some View {
        HStack(spacing: 8) {
            Text(lifestyleEmoji(for: text))
                .font(.app(size: 16))
            Text(text)
                .font(.app(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    private func lifestyleEmoji(for lifestyle: String) -> String {
        switch lifestyle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "all lifestyles":
            return "⭐️"
        case "backpacking":
            return "🎒"
        case "digital nomad":
            return "💻"
        case "gap year":
            return "👋"
        case "studying abroad":
            return "📚"
        case "living abroad":
            return "🏠"
        case "au pair":
            return "🤹"
        default:
            return "✨"
        }
    }

    private func heroPill(text: String, systemImage: String, imageColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(imageColor)
            Text(text)
                .font(.app(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .accessibilityLabel(Text(text))
    }

    private func interestTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            Text(text)
                .font(.app(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func userImageView(_ user: User, contentMode: ContentMode) -> some View {
        if let url = URL(string: user.image), url.scheme != nil {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
        } else if let uiImage = UIImage(named: user.image) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Compact Controls
private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

struct CompactPillButton: View {
    enum Style {
        case light
        case accent
    }

    let icon: String
    let text: String
    var style: Style = .light
    let action: () -> Void

    var body: some View {
        let foreground: Color = style == .accent ? .white : .primary
        let background: Color = style == .accent ? Color.appAccent : Color(.systemGray5)
        let strokeColor: Color = style == .accent ? .clear : Color(.separator)

        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(text)
                    .font(.app(size: 15, weight: .bold))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(strokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth = proposal.width ?? 0
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var maxWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            let itemWidth = size.width
            let wouldExceed = currentRowWidth > 0 && (currentRowWidth + spacing + itemWidth > availableWidth)

            if wouldExceed {
                totalHeight += rowHeight + (totalHeight > 0 ? spacing : 0)
                currentRowWidth = itemWidth
                rowHeight = size.height
            } else {
                currentRowWidth += itemWidth + (currentRowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
            maxWidth = max(maxWidth, min(currentRowWidth, availableWidth))
        }
        totalHeight += rowHeight

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX > bounds.minX && currentX + size.width > maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
