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
    
    // 순차 페이드인 애니메이션을 위한 opacity 상태
    @State private var titleOpacity: Double = 0.0
    @State private var descriptionOpacity: Double = 0.0
    @State private var selectTextOpacity: Double = 0.0
    @State private var formOpacity: Double = 0.0
    @State private var buttonOpacity: Double = 0.0
    @State private var helperTextOpacity: Double = 0.0
    
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
            
            // 세계 지도 배경 이미지
            Image("world-map")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(0.3)
                .ignoresSafeArea()
            
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
                        .opacity(titleOpacity)
                    
                    // 앱 설명
                    Text(NSLocalizedString("initial_setup.description", comment: "Set alarms for different cities"))
                        .font(.geist(size: 18, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(descriptionOpacity)
                    
                    // 국가 선택 안내 텍스트
                    Text(NSLocalizedString("initial_setup.select_primary_country", comment: "Select your primary country."))
                        .font(.geist(size: 16, weight: .medium))
                        .foregroundColor(.appTextPrimary)
                        .padding(.top, 32)
                        .opacity(selectTextOpacity)
                    
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
                    .opacity(formOpacity)
                    
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
                    .opacity(buttonOpacity)
                    
                    // 보조 텍스트
                    Text(NSLocalizedString("initial_setup.change_later", comment: "You can change it anytime in Settings."))
                        .font(.geist(size: 14, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .padding(.top, 8)
                        .opacity(helperTextOpacity)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showCountrySelection) {
            NavigationView {
                CountrySelectionView(selectedCountry: $selectedCountry)
            }
        }
        .onAppear {
            // 순차 페이드인 애니메이션
            withAnimation(.easeIn(duration: 0.6).delay(0.1)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                descriptionOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                selectTextOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
                formOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.9)) {
                buttonOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(1.1)) {
                helperTextOpacity = 1.0
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

