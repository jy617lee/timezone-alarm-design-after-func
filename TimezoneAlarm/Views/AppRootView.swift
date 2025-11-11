//
//  AppRootView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications

struct AppRootView: View {
    @State private var showSplash = true
    @State private var hasRequestedPermission = false
    @State private var showInitialSetup = false
    @State private var isSetupComplete = false
    
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
        .onChange(of: showSplash) { oldValue, newValue in
            // 스플래시가 끝나면 권한 요청
            if !newValue && !hasRequestedPermission {
                hasRequestedPermission = true
                requestNotificationPermission()
            }
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            debugLog("📱 알림 권한 상태 확인: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                debugLog("📱 알림 권한이 없습니다. 권한 요청 중...")
                let granted = await AlarmScheduler.shared.requestAuthorization()
                debugLog("📱 권한 요청 결과: \(granted ? "허용됨" : "거부됨")")
            case .denied:
                debugLog("⚠️ 알림 권한이 거부되었습니다.")
            case .authorized, .provisional, .ephemeral:
                debugLog("✅ 알림 권한이 이미 허용되어 있습니다.")
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

