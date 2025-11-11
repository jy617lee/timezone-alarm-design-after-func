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
    @State private var iconOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var descriptionOpacity: Double = 0.0
    @State private var mapOpacity: Double = 0.0
    @State private var formOpacity: Double = 0.0
    @State private var helperTextOpacity: Double = 0.0
    @State private var buttonOpacity: Double = 0.0
    
    private var isFormValid: Bool {
        selectedCountry != nil
    }
    
    var body: some View {
        ZStack {
            // 대각선 그라데이션 배경
            // top-left, bottom-right: appBackgroundBottom (진한 색)
            // center: appBackgroundTop (밝은 색)
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.appBackgroundBottom, location: 0.0), // top-left
                    .init(color: Color.appBackgroundTop, location: 0.5), // center
                    .init(color: Color.appBackgroundBottom, location: 1.0) // bottom-right
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                .zIndex(10) // 스킵 버튼이 다른 요소 위에 표시되도록
                
                Spacer()
                
                // 컨텐츠 영역
                VStack(spacing: 24) {
                    // 앱 아이콘
                    Image("alarm-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .opacity(iconOpacity)
                    
                    // 타이틀과 설명 그룹
                    VStack(spacing: 8) {
                        // 타이틀
                        Text(NSLocalizedString("initial_setup.title", comment: "Stay in sync with every city."))
                            .font(.geist(size: 32, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                            .opacity(titleOpacity)
                        
                        // 앱 설명
                        Text(NSLocalizedString("initial_setup.description", comment: "Set alarms for different cities"))
                            .font(.geist(size: 18, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .opacity(descriptionOpacity)
                    }
                    
                    // 세계 지도 이미지 (설명과 폼 사이)
                    Image("world-map")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .opacity(0.3)
                        .padding(.vertical, 16)
                        .opacity(mapOpacity)
                    
                    // 국가 선택 폼 (FormSection 사용, 설정 화면과 동일한 스타일)
                    VStack(spacing: 8) {
                        FormSection(
                            title: NSLocalizedString("initial_setup.select_primary_country", comment: "Select your primary country.")
                        ) {
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
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 보조 텍스트 (폼 바로 밑)
                        Text(NSLocalizedString("initial_setup.change_later", comment: "You can change it anytime in Settings."))
                            .font(.geist(size: 14, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                            .opacity(helperTextOpacity)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .opacity(formOpacity)
                    
                    // Continue 버튼
                    Button(action: {
                        completeSetup()
                    }) {
                        Text(NSLocalizedString("initial_setup.continue", comment: "Continue"))
                            .font(.geist(size: 17, weight: .semibold))
                            .foregroundColor(.appTextOnPrimary)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(isFormValid ? Color.appPrimary : Color.appPrimary.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .opacity(buttonOpacity)
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
                iconOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.2)) {
                titleOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                descriptionOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
                mapOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                formOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
                helperTextOpacity = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.6).delay(0.9)) {
                buttonOpacity = 1.0
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

