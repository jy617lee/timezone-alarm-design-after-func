//
//  TimezoneAlarmApp.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications

@main
struct TimezoneAlarmApp: App {
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    init() {
        // 알람 권한 요청
        Task {
            await AlarmScheduler.shared.requestAuthorization()
        }
        
        // 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationDelegate)
        }
    }
}

// 알림 델리게이트
@MainActor
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var activeAlarm: Alarm?
    
    // 알림이 앱이 포그라운드에 있을 때 표시
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 포그라운드에서도 알림 표시
        completionHandler([.banner, .sound, .badge])
        
        // 알람 정보 추출
        if let alarmId = notification.request.content.userInfo["alarmId"] as? String,
           let alarmName = notification.request.content.userInfo["alarmName"] as? String,
           let alarmHour = notification.request.content.userInfo["alarmHour"] as? Int,
           let alarmMinute = notification.request.content.userInfo["alarmMinute"] as? Int,
           let timezoneIdentifier = notification.request.content.userInfo["timezoneIdentifier"] as? String,
           let countryName = notification.request.content.userInfo["countryName"] as? String,
           let countryFlag = notification.request.content.userInfo["countryFlag"] as? String {
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            Task { @MainActor in
                self.activeAlarm = alarm
            }
        }
    }
    
    // 알림을 탭했을 때
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let alarmId = response.notification.request.content.userInfo["alarmId"] as? String,
           let alarmName = response.notification.request.content.userInfo["alarmName"] as? String,
           let alarmHour = response.notification.request.content.userInfo["alarmHour"] as? Int,
           let alarmMinute = response.notification.request.content.userInfo["alarmMinute"] as? Int,
           let timezoneIdentifier = response.notification.request.content.userInfo["timezoneIdentifier"] as? String,
           let countryName = response.notification.request.content.userInfo["countryName"] as? String,
           let countryFlag = response.notification.request.content.userInfo["countryFlag"] as? String {
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            Task { @MainActor in
                self.activeAlarm = alarm
            }
        }
        
        completionHandler()
    }
}

