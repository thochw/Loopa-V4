//
//  ProfileSettingsScreen.swift
//  ios loopa
//
//  Created by Codex on 2026-02-04.
//

import SwiftUI

struct ProfileSettingsScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var unitIsKm: Bool = true
    @State private var hideNearbyDistance: Bool = false
    @State private var hideActiveStatus: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    settingsCard
                    secondaryCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
            }
            .padding(.leading, 20)

            Text("Settings")
                .font(.app(size: 32, weight: .bold))
                .foregroundStyle(.black)
                .padding(.leading, 38)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            rowWithChevron(title: "Unit of measurement", value: unitIsKm ? "km" : "mi")
            divider
            toggleRow(title: "Hide my nearby distance", isOn: $hideNearbyDistance)
            divider
            toggleRow(title: "Hide active status", isOn: $hideActiveStatus, badge: "Pro Feature")
            divider
            row(title: "Report an issue")
            divider
            row(title: "Leave a review")
            divider
            row(title: "Restore Purchases")
            divider
            row(title: "Redeem Promo Code")
            divider
            row(title: "Clear Cache")
        }
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        )
    }

    private var secondaryCard: some View {
        VStack(spacing: 0) {
            row(title: "Community Guidelines")
            divider
            row(title: "Terms and Conditions")
            divider
            row(title: "Privacy Policy")
            divider
            row(title: "Logout")
            divider
            row(title: "Delete Account", isDestructive: true)
        }
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        )
        .padding(.bottom, 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 1)
            .padding(.leading, 4)
    }

    private func row(title: String, isDestructive: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.app(size: 16, weight: .medium))
                .foregroundStyle(isDestructive ? Color.red : Color.black)
            Spacer()
        }
        .padding(.vertical, 18)
    }

    private func rowWithChevron(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.app(size: 16, weight: .medium))
                .foregroundStyle(.black)
            Spacer()
            HStack(spacing: 6) {
                Text(value)
                    .font(.app(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 18)
    }

    private func toggleRow(title: String, isOn: Binding<Bool>, badge: String? = nil) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.app(size: 16, weight: .medium))
                .foregroundStyle(.black)

            if let badge {
                Text(badge)
                    .font(.app(size: 12, weight: .semibold))
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.appAccent)
        }
        .padding(.vertical, 14)
    }
}
