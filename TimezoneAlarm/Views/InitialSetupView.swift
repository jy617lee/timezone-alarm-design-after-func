//
//  InitialSetupView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct InitialSetupView: View {
    @Binding var isSetupComplete: Bool
    @State private var selectedCountry: Country?
    @State private var showCountrySelection = false
    
    private var isFormValid: Bool {
        selectedCountry != nil
    }
    
    var body: some View {
        ZStack {
            // 대각선 그라데이션 배경
            // top-left, bottom-right: appBackgroundBottom
            // center: appBackgroundTop
            AngularGradient(
                gradient: Gradient(colors: [
                    Color.appBackgroundBottom,
                    Color.appBackgroundTop,
                    Color.appBackgroundBottom
                ]),
                center: .center,
                angle: .degrees(135)
            )
            .ignoresSafeArea()
            
            // 세계 지도 배경 이미지 (추후 추가)
            
            VStack(spacing: 0) {
                // 스킵 버튼 (우측 상단)
                HStack {
                    Spacer()
                    Button(action: {
                        skipSetup()
                    }) {
                        Text(NSLocalizedString("initial_setup.skip", comment: "Skip for now"))
                            .font(.geist(size: 16, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // 컨텐츠 영역
                VStack(spacing: 24) {
                    // 타이틀
                    Text(NSLocalizedString("initial_setup.title", comment: "Stay in sync with every city."))
                        .font(.geist(size: 32, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // 앱 설명
                    Text(NSLocalizedString("initial_setup.description", comment: "Set alarms for different cities"))
                        .font(.geist(size: 18, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // 국가 선택 안내 텍스트
                    Text(NSLocalizedString("initial_setup.select_primary_country", comment: "Select your primary country."))
                        .font(.geist(size: 16, weight: .medium))
                        .foregroundColor(.appTextPrimary)
                        .padding(.top, 32)
                    
                    // 국가 선택 폼
                    Button(action: {
                        showCountrySelection = true
                    }) {
                        HStack {
                            if let country = selectedCountry {
                                Text(country.flag)
                                    .font(.geist(size: 24, weight: .regular))
                                Text(country.name)
                                    .font(.geist(size: 16, weight: .medium))
                                    .foregroundColor(.appTextPrimary)
                            } else {
                                Text(NSLocalizedString("initial_setup.country_placeholder", comment: "Tap to select country"))
                                    .font(.geist(size: 16, weight: .regular))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.geist(size: 14, weight: .medium))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(16)
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appCardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                    
                    // Continue 버튼
                    Button(action: {
                        completeSetup()
                    }) {
                        Text(NSLocalizedString("initial_setup.continue", comment: "Continue"))
                            .font(.geist(size: 17, weight: .semibold))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.appPrimary : Color.appPrimary.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    
                    // 보조 텍스트
                    Text(NSLocalizedString("initial_setup.change_later", comment: "You can change it anytime in Settings."))
                        .font(.geist(size: 14, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .padding(.top, 8)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showCountrySelection) {
            NavigationView {
                CountrySelectionView(selectedCountry: $selectedCountry)
            }
        }
    }
    
    private func completeSetup() {
        guard let country = selectedCountry else { return }
        UserDefaults.standard.set(country.id, forKey: "defaultCountryId")
        UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
        isSetupComplete = true
    }
    
    private func skipSetup() {
        UserDefaults.standard.set(false, forKey: "hasCompletedInitialSetup")
        isSetupComplete = true
    }
}

#Preview {
    InitialSetupView(isSetupComplete: .constant(false))
}

