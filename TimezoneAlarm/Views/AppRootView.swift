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
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
        .onChange(of: showSplash) { newValue in
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

