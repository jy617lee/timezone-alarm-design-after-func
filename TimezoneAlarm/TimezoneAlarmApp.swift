//
//  TimezoneAlarmApp.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications
import AVFoundation

@main
struct TimezoneAlarmApp: App {
    init() {
        print("🚀 TimezoneAlarm 앱 시작!")
        
        // 백그라운드 오디오 재생을 위한 오디오 세션 설정
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ 백그라운드 오디오 세션 활성화")
        } catch {
            print("⚠️ 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
        
        // 알림 델리게이트 설정 (싱글톤 인스턴스 사용)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        print("✅ 알림 델리게이트 설정 완료")
        
        // 알람 권한 확인 및 요청
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            print("📱 알림 권한 상태 확인: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                print("📱 알림 권한이 없습니다. 권한 요청 중...")
                let granted = await AlarmScheduler.shared.requestAuthorization()
                print("📱 권한 요청 결과: \(granted ? "허용됨" : "거부됨")")
            case .denied:
                print("⚠️ 알림 권한이 거부되었습니다.")
            case .authorized, .provisional, .ephemeral:
                print("✅ 알림 권한이 이미 허용되어 있습니다.")
            @unknown default:
                print("⚠️ 알 수 없는 권한 상태")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationDelegate.shared)
        }
    }
}

// 알림 델리게이트
@MainActor
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    @Published var activeAlarm: Alarm?
    
    private override init() {
        super.init()
        print("📱 NotificationDelegate 싱글톤 인스턴스 생성")
    }
    
    // 알림이 앱이 포그라운드에 있을 때 표시
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let currentTime = Date()
        print("🔔🔔🔔 willPresent 호출됨 - 알림 도착! (시간: \(currentTime))")
        print("   - 제목: \(notification.request.content.title)")
        print("   - 내용: \(notification.request.content.body)")
        print("   - 사용자 정보: \(notification.request.content.userInfo)")
        print("   - 트리거 타입: \(type(of: notification.request.trigger))")
        
        // 포그라운드에서도 알림 표시 (사운드 없음 - 백그라운드 오디오만 사용)
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .list])
        } else {
            completionHandler([.alert, .badge])
        }
        
        // 알람 정보 추출
        if let alarmId = notification.request.content.userInfo["alarmId"] as? String,
           let alarmName = notification.request.content.userInfo["alarmName"] as? String,
           let alarmHour = notification.request.content.userInfo["alarmHour"] as? Int,
           let alarmMinute = notification.request.content.userInfo["alarmMinute"] as? Int,
           let timezoneIdentifier = notification.request.content.userInfo["timezoneIdentifier"] as? String,
           let countryName = notification.request.content.userInfo["countryName"] as? String,
           let countryFlag = notification.request.content.userInfo["countryFlag"] as? String {
            
            print("✅ 알람 정보 추출 성공: \(alarmName)")
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            // 알림 ID를 로컬 변수로 추출 (데이터 레이스 방지)
            let notificationId = notification.request.identifier
            
            Task { @MainActor in
                print("📱 activeAlarm 설정 중: \(alarm.name)")
                self.activeAlarm = alarm
                print("✅ activeAlarm 설정 완료")
                
                // 백그라운드에서도 연속 사운드 재생 시작 (앱이 실행 중일 때만)
                self.startBackgroundAudioPlayback(for: alarm)
                
                // 체인 알림 예약: 알림이 도착할 때마다 다음 알림(10초 후) 예약
                // 체인 인덱스는 알림 ID에서 추출 (chain-{index} 형식)
                var chainIndex = 0
                
                if notificationId.contains("-chain-") {
                    // 이미 체인 알림인 경우, 다음 인덱스로
                    if let range = notificationId.range(of: "-chain-") {
                        let indexString = String(notificationId[range.upperBound...])
                        if let index = Int(indexString) {
                            chainIndex = index + 1
                        }
                    }
                } else {
                    // 첫 번째 알림인 경우, chain-0으로 시작
                    chainIndex = 0
                }
                
                print("🔗 다음 체인 알림 예약: chain-\(chainIndex)")
                AlarmScheduler.shared.scheduleChainNotification(for: alarm, chainIndex: chainIndex)
            }
        } else {
            print("❌ 알람 정보 추출 실패")
        }
    }
    
    // 알림을 탭했을 때 (백그라운드에서 알림을 탭하여 앱이 열릴 때)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 didReceive 호출됨 - 알림 탭됨!")
        print("   - 액션: \(response.actionIdentifier)")
        
        // 알림을 탭한 경우에만 처리 (자동으로 앱이 열린 경우)
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
            completionHandler()
            return
        }
        
        if let alarmId = response.notification.request.content.userInfo["alarmId"] as? String,
           let alarmName = response.notification.request.content.userInfo["alarmName"] as? String,
           let alarmHour = response.notification.request.content.userInfo["alarmHour"] as? Int,
           let alarmMinute = response.notification.request.content.userInfo["alarmMinute"] as? Int,
           let timezoneIdentifier = response.notification.request.content.userInfo["timezoneIdentifier"] as? String,
           let countryName = response.notification.request.content.userInfo["countryName"] as? String,
           let countryFlag = response.notification.request.content.userInfo["countryFlag"] as? String {
            
            print("✅ 알람 정보 추출 성공: \(alarmName)")
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            // 알림 ID를 로컬 변수로 추출 (데이터 레이스 방지)
            let notificationId = response.notification.request.identifier
            
            Task { @MainActor in
                print("📱 activeAlarm 설정 중 (didReceive): \(alarm.name)")
                self.activeAlarm = alarm
                // 표시된 알림 제거
                AlarmScheduler.shared.removeDeliveredNotification(for: alarm)
                
                // 백그라운드에서도 연속 사운드 재생 시작 (앱이 실행 중일 때만)
                self.startBackgroundAudioPlayback(for: alarm)
                
                // 체인 알림 예약: 알림이 도착할 때마다 다음 알림(10초 후) 예약
                var chainIndex = 0
                
                if notificationId.contains("-chain-") {
                    // 이미 체인 알림인 경우, 다음 인덱스로
                    if let range = notificationId.range(of: "-chain-") {
                        let indexString = String(notificationId[range.upperBound...])
                        if let index = Int(indexString) {
                            chainIndex = index + 1
                        }
                    }
                } else {
                    // 첫 번째 알림인 경우, chain-0으로 시작
                    chainIndex = 0
                }
                
                print("🔗 다음 체인 알림 예약: chain-\(chainIndex)")
                AlarmScheduler.shared.scheduleChainNotification(for: alarm, chainIndex: chainIndex)
            }
        } else {
            print("❌ 알람 정보 추출 실패")
        }
        
        completionHandler()
    }
    
    // 백그라운드에서 연속 사운드 재생
    private var backgroundAudioPlayer: AVAudioPlayer?
    private var backgroundAudioTimer: Timer?
    
    func startBackgroundAudioPlayback(for alarm: Alarm) {
        // 이미 재생 중이면 중복 시작 방지
        if let player = backgroundAudioPlayer, player.isPlaying {
            print("🔊 백그라운드 오디오가 이미 재생 중입니다")
            return
        }
        
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            print("⚠️ alarm.wav 파일을 찾을 수 없습니다")
            return
        }
        
        do {
            // 오디오 세션 활성화 (백그라운드 재생 허용)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 기존 플레이어 정리
            backgroundAudioPlayer?.stop()
            backgroundAudioPlayer = nil
            
            // 오디오 플레이어 생성 및 재생
            backgroundAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            backgroundAudioPlayer?.numberOfLoops = -1 // 무한 루프
            backgroundAudioPlayer?.volume = 1.0
            backgroundAudioPlayer?.play()
            
            print("🔊 백그라운드 연속 사운드 재생 시작 (끊김 없이)")
            
            // 백그라운드에서도 계속 재생되도록 유지
            // dismiss 시 정지됨
        } catch {
            print("❌ 백그라운드 오디오 재생 실패: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundAudioPlayback() {
        backgroundAudioPlayer?.stop()
        backgroundAudioPlayer = nil
        backgroundAudioTimer?.invalidate()
        backgroundAudioTimer = nil
        print("🔇 백그라운드 오디오 재생 정지")
    }
}

