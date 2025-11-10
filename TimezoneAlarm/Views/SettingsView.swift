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
                            Text(NSLocalizedString("settings.default_country", comment: "Default country"))
                            Spacer()
                            if let country = selectedCountry {
                                HStack(spacing: 8) {
                                    Text(country.flag)
                                    Text(country.name)
                                        .foregroundColor(.appTextSecondary)
                                }
                            } else {
                                Text(NSLocalizedString("settings.select_country", comment: "Select country"))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("settings.default_country", comment: "Default country header"))
                } footer: {
                    Text(NSLocalizedString("settings.default_country_footer", comment: "Default country footer"))
                }
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("button.back", comment: "Back button")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("button.save", comment: "Save button")) {
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

