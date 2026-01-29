//
//  TravelersFilterView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI

struct TravelersFilterView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Filter states
    @State private var selectedGenders: Set<String> = []
    @State private var selectedAgeRange: String = "All Ages"
    @State private var selectedLifestyle: String = "All Lifestyles"
    @State private var selectedNationalities: Set<String> = []
    @State private var showNationalities = false
    
    private let genders = ["Men", "Women"]
    private let ageRanges = ["All Ages", "18-25", "26-35", "36-45", "46-55", "56+"]
    private let nationalities: [(name: String, flag: String)] = [
        ("Canada", "🇨🇦"),
        ("United States", "🇺🇸"),
        ("France", "🇫🇷"),
        ("United Kingdom", "🇬🇧"),
        ("Australia", "🇦🇺"),
        ("Germany", "🇩🇪")
    ]
    private let lifestyles: [(name: String, emoji: String)] = [
        ("All Lifestyles", "⭐️"),
        ("Backpacking", "🎒"),
        ("Digital Nomad", "💻"),
        ("Gap Year", "👋"),
        ("Studying Abroad", "📚"),
        ("Living Abroad", "🏠"),
        ("Au Pair", "🤹")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Filters")
                                    .font(.app(size: 34, weight: .bold))
                                    .foregroundStyle(.primary)
                                
                                Text("Customize What Type of Travelers You See")
                                    .font(.app(size: 15, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Filter Sections
                    ScrollView {
                        VStack(spacing: 20) {
                            // Gender Section
                            filterCard(title: "Gender", currentState: getGenderState()) {
                                VStack(spacing: 12) {
                                    ForEach(genders, id: \.self) { gender in
                                        genderRow(gender: gender)
                                    }
                                }
                            }
                            
                            // Age Range Section
                            filterCard(title: "Age Range", currentState: selectedAgeRange == "All Ages" ? "Showing All Ages" : "Showing Ages \(selectedAgeRange)") {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(ageRanges, id: \.self) { age in
                                        ageButton(age: age)
                                    }
                                }
                            }
                            
                            // Nationalities Section
                            filterCard(title: "Nationalities", currentState: getNationalityState()) {
                                VStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showNationalities.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text("Select countries")
                                                .font(.app(size: 16, weight: .semibold))
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: showNationalities ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if showNationalities {
                                        VStack(spacing: 10) {
                                            ForEach(nationalities, id: \.name) { nationality in
                                                nationalityRow(nationality: nationality.name, flag: nationality.flag)
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                            }
                            
                            // Travel Lifestyle Section
                            filterCard(title: "Travel Lifestyle", currentState: selectedLifestyle == "All Lifestyles" ? "Showing All Traveler Types" : "Showing \(selectedLifestyle)") {
                                VStack(spacing: 10) {
                                    ForEach(lifestyles, id: \.name) { lifestyle in
                                        lifestyleButton(lifestyle: lifestyle.name, emoji: lifestyle.emoji)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for bottom buttons
                    }
                    
                    // Bottom Action Buttons
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                // Reset all filters
                                selectedGenders.removeAll()
                                selectedAgeRange = "All Ages"
                                selectedLifestyle = "All Lifestyles"
                                selectedNationalities.removeAll()
                            }) {
                                Text("Reset")
                                    .font(.app(size: 17, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                // Apply filters and dismiss
                                dismiss()
                            }) {
                                Text("Apply")
                                    .font(.app(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .tint(Color.appAccent)
    }
    
    private func filterCard<Content: View>(title: String, currentState: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(size: 17, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(currentState)
                    .font(.app(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func genderRow(gender: String) -> some View {
        Button(action: {
            if selectedGenders.contains(gender) {
                selectedGenders.remove(gender)
            } else {
                selectedGenders.insert(gender)
            }
        }) {
            HStack {
                Text(gender.lowercased() == "men" ? "🙋‍♂️" : "🙆‍♀️")
                    .font(.system(size: 20))
                
                Text(gender)
                    .font(.app(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedGenders.contains(gender) {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "square")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func ageButton(age: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedAgeRange = age
            }
        }) {
            Text(age)
                .font(.app(size: 15, weight: .medium))
                .foregroundStyle(selectedAgeRange == age ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    selectedAgeRange == age
                        ? LinearGradient(
                            colors: [Color.appAccent, Color.appAccent.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            selectedAgeRange == age ? Color.clear : Color(.systemGray5),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private func nationalityRow(nationality: String, flag: String) -> some View {
        Button(action: {
            if selectedNationalities.contains(nationality) {
                selectedNationalities.remove(nationality)
            } else {
                selectedNationalities.insert(nationality)
            }
        }) {
            HStack {
                Text(flag)
                    .font(.system(size: 20))
                
                Text(nationality)
                    .font(.app(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if selectedNationalities.contains(nationality) {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.tint)
                } else {
                    Image(systemName: "square")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func lifestyleButton(lifestyle: String, emoji: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedLifestyle = lifestyle
            }
        }) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(lifestyle)
                    .font(.app(size: 15, weight: .medium))
                    .foregroundStyle(selectedLifestyle == lifestyle ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                    selectedLifestyle == lifestyle
                    ? LinearGradient(
                        colors: [Color.appAccent, Color.appAccent.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white, Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        selectedLifestyle == lifestyle ? Color.clear : Color(.systemGray5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getGenderState() -> String {
        if selectedGenders.isEmpty {
            return "Showing Everybody"
        } else if selectedGenders.count == 2 {
            return "Showing Everybody"
        } else {
            return "Showing \(selectedGenders.first ?? "")"
        }
    }
    
    private func getNationalityState() -> String {
        if selectedNationalities.isEmpty {
            return "Showing All Nationalities"
        }
        if selectedNationalities.count == 1, let nationality = selectedNationalities.first {
            return "Showing \(nationality)"
        }
        return "Showing \(selectedNationalities.count) Nationalities"
    }
}
