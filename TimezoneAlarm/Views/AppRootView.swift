//
//  AppRootView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications
import AVFoundation

struct AppRootView: View {
    @State private var showSplash = true
    @State private var hasRequestedPermission = false
    @State private var showInitialSetup = false
    @State private var isSetupComplete = false
    @Environment(\.scenePhase) private var scenePhase
    
    private var hasCompletedInitialSetup: Bool {
        UserDefaults.standard.bool(forKey: "hasCompletedInitialSetup")
    }
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
            } else if !isSetupComplete && !hasCompletedInitialSetup {
                InitialSetupView(isSetupComplete: $isSetupComplete)
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .animation(.easeInOut(duration: 0.6), value: isSetupComplete)
        .onAppear {
            // 초기 설정 완료 여부 확인
            isSetupComplete = hasCompletedInitialSetup
        }
        .onChange(of: showSplash) { newValue in
            // 스플래시가 끝나면 권한 요청
            if !newValue && !hasRequestedPermission {
                hasRequestedPermission = true
                requestNotificationPermission()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            // 백그라운드/포그라운드 전환 시 오디오 세션 재설정
            // 백그라운드에서 소리가 작아지는 문제 해결
            if newPhase == .background || newPhase == .active {
                // 오디오가 재생 중이면 오디오 세션 재설정
                if NotificationDelegate.shared.isAudioPlaying {
                    Task { @MainActor in
                        // 약간의 지연을 두어 전환이 완료된 후 재설정
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                        NotificationDelegate.shared.ensureMaximumVolume()
                        // 오디오 세션 재설정을 위해 setupAudioSession 호출
                        // (내부적으로 호출되도록 ensureMaximumVolume에서 처리하거나 별도 메서드 필요)
                    }
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            debugLog("📱 알림 권한 상태 확인: \(settings.authorizationStatus.rawValue)")
            debugLog("📱 상세 설정 - alert: \(settings.alertSetting.rawValue), sound: \(settings.soundSetting.rawValue), badge: \(settings.badgeSetting.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                debugLog("📱 알림 권한이 없습니다. 권한 요청 중...")
                let granted = await AlarmScheduler.shared.requestAuthorization()
                debugLog("📱 권한 요청 결과: \(granted ? "허용됨" : "거부됨")")
                
                // 권한 요청 후 다시 확인
                let newSettings = await center.notificationSettings()
                debugLog("📱 권한 요청 후 설정 - alert: \(newSettings.alertSetting.rawValue), sound: \(newSettings.soundSetting.rawValue), badge: \(newSettings.badgeSetting.rawValue)")
            case .denied:
                debugLog("⚠️ 알림 권한이 거부되었습니다.")
            case .authorized, .provisional, .ephemeral:
                debugLog("✅ 알림 권한이 이미 허용되어 있습니다.")
                // soundSetting이 .enabled가 아니면 경고
                if settings.soundSetting != .enabled {
                    debugLog("⚠️⚠️⚠️ soundSetting이 .enabled가 아닙니다! (\(settings.soundSetting.rawValue))")
                    debugLog("   → 앱 삭제 후 재설치 필요할 수 있음")
                }
            @unknown default:
                debugLog("⚠️ 알 수 없는 권한 상태")
            }
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(NotificationDelegate.shared)
}

