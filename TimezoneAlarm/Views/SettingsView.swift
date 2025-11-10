//
//  SettingsView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCountry: Country?
    
    private var isFormValid: Bool {
        selectedCountry != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink {
                        CountrySelectionView(selectedCountry: $selectedCountry)
                    } label: {
                        HStack {
                            Text("Default Country")
                            Spacer()
                            if let country = selectedCountry {
                                HStack(spacing: 8) {
                                    Text(country.flag)
                                    Text(country.name)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Country")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Default Country")
                } footer: {
                    Text("This country will be used as the default when creating new alarms.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDefaultCountry()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadDefaultCountry()
            }
        }
    }
    
    private func loadDefaultCountry() {
        if let countryId = UserDefaults.standard.string(forKey: "defaultCountryId"),
           let country = Country.popularCountries.first(where: { $0.id == countryId }) {
            selectedCountry = country
        }
    }
    
    private func saveDefaultCountry() {
        guard let country = selectedCountry else { return }
        UserDefaults.standard.set(country.id, forKey: "defaultCountryId")
        dismiss()
    }
}

#Preview {
    SettingsView()
}

