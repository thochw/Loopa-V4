//
//  CitySearchView.swift
//  ios loopa
//
//  Created by Thomas CHANG-HING-WING on 2026-01-17.
//

import SwiftUI
import MapKit

struct CitySearchView: View {
    let cities: [City]
    let currentCity: String
    let onCitySelected: (City) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Trending destinations (top cities)
    private var trendingCities: [City] {
        let topCities = ["Tokyo", "Madrid", "London", "Amsterdam", "Cape Town", "New York", "Bali", "Barcelona"]
        return cities.filter { city in
            topCities.contains { topCity in
                city.name.localizedCaseInsensitiveContains(topCity)
            }
        }
    }
    
    private var filteredCities: [City] {
        if searchText.isEmpty {
            return trendingCities
        }
        return cities.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Simple Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search for a city...", text: $searchText)
                        .font(.app(size: 17, weight: .regular))
                        .foregroundStyle(.primary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($isSearchFocused)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                searchText = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Cities List
                if filteredCities.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "Aucune ville trouvée",
                        systemImage: "map",
                        description: Text("Essayez une autre recherche")
                    )
                    .transition(.opacity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Section Title
                            if searchText.isEmpty {
                                Text("Trending Destinations")
                                    .font(.app(size: 22, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 16)
                                    .transition(.opacity)
                            }
                            
                            // Cities Grid
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredCities.enumerated()), id: \.element.id) { index, city in
                                    cityCard(city: city, index: index)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .move(edge: .leading)),
                                            removal: .opacity
                                        ))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        .padding(.top, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                // Auto-focus search field for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchText)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: filteredCities.count)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func cityCard(city: City, index: Int) -> some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onCitySelected(city)
            }
        }) {
            HStack(spacing: 16) {
                // Flag in square format
                Text(city.flag)
                    .font(.app(size: 32))
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(.systemGray5), lineWidth: 0.5)
                    )
                
                // City Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(getCityName(city))
                            .font(.app(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        if currentCity == city.name {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.tint)
                        }
                    }
                    
                    Text(city.name)
                        .font(.app(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        currentCity == city.name 
                            ? Color.accentColor.opacity(0.3)
                            : Color.clear,
                        lineWidth: 2
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.8).delay(Double(index) * 0.03),
            value: currentCity
        )
    }
    
    private func getCityName(_ city: City) -> String {
        // Extract just the city name (before comma)
        let components = city.name.components(separatedBy: ", ")
        return components.first ?? city.name
    }
}
