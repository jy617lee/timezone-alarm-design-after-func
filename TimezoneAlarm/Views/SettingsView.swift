//
//  SettingsView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCity: City?
    
    private var isFormValid: Bool {
        selectedCity != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 그라데이션 백그라운드
                LinearGradient(
                    colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 컨텐츠
                    VStack(spacing: 16) {
                        FormSection(
                            title: NSLocalizedString("settings.default_city", comment: "Default city header")
                        ) {
                            NavigationLink {
                                CitySelectionView(selectedCity: $selectedCity)
                            } label: {
                                HStack {
                                    if let city = selectedCity {
                                        Text(city.countryFlag)
                                            .font(.geist(size: 24, weight: .regular))
                                        Text(city.name)
                                            .font(.geist(size: 16, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                    } else {
                                        Text(NSLocalizedString("settings.select_city", comment: "Select city"))
                                            .font(.geist(size: 16, weight: .regular))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.geist(size: 14, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle(NSLocalizedString("settings.title", comment: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appHeaderBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // NavigationBar 버튼 배경 제거
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.clear
                
                // 버튼 배경 제거
                let buttonAppearance = UIBarButtonItemAppearance()
                buttonAppearance.normal.backgroundImage = UIImage()
                buttonAppearance.highlighted.backgroundImage = UIImage()
                buttonAppearance.disabled.backgroundImage = UIImage()
                appearance.buttonAppearance = buttonAppearance
                appearance.doneButtonAppearance = buttonAppearance
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                loadDefaultCity()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(NSLocalizedString("settings.title", comment: "Settings"))
                        .font(.geist(size: 20, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.geist(size: 18, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveDefaultCity()
                    }) {
                        Text(NSLocalizedString("button.save", comment: "Save button"))
                            .font(.geist(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isFormValid ? Color.appPrimary : Color.appPrimary.opacity(0.5))
                            .cornerRadius(20)
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.plain)
                    .background(Color.clear)
                }
            }
        }
    }
    
    private func loadDefaultCity() {
        if let timezoneId = UserDefaults.standard.string(forKey: "defaultTimezoneId"),
           let city = City.popularCities.first(where: { $0.timezoneIdentifier == timezoneId }) {
            selectedCity = city
        }
    }
    
    private func saveDefaultCity() {
        guard let city = selectedCity else { return }
        UserDefaults.standard.set(city.timezoneIdentifier, forKey: "defaultTimezoneId")
        dismiss()
    }
}

#Preview {
    SettingsView()
}

