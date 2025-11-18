//
//  TimezoneAlarmApp.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox
import FirebaseCore
import FirebaseAnalytics

@main
struct TimezoneAlarmApp: App {
    init() {
        debugLog("🚀 TimezoneAlarm 앱 시작!")
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 디버그 모드에서는 Analytics 수집 비활성화
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        debugLog("✅ Firebase 초기화 완료 (Analytics 수집 비활성화 - DEBUG 모드)")
        #else
        debugLog("✅ Firebase 초기화 완료")
        #endif
        
        // 오디오 세션은 실제로 오디오를 재생할 때만 설정
        // 푸시 알림의 사운드는 iOS가 자동으로 처리
        
        // 알림 델리게이트 설정 (싱글톤 인스턴스 사용)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        debugLog("✅ 알림 델리게이트 설정 완료")
        
        // 권한 요청은 스플래시 화면이 끝난 후 AppRootView에서 처리
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(NotificationDelegate.shared)
        }
    }
}

// 알림 델리게이트
@MainActor
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    @Published var activeAlarm: Alarm?
    
    // dismiss된 알람 ID를 추적 (해당 알람의 체인 알림 예약 방지)
    private var dismissedAlarmIds: Set<UUID> = []
    
    private override init() {
        super.init()
        debugLog("📱 NotificationDelegate 싱글톤 인스턴스 생성")
    }
    
    // 알람 dismiss 처리 (체인 알림 예약 중단)
    func dismissAlarm(_ alarm: Alarm) {
        dismissedAlarmIds.insert(alarm.id)
        activeAlarm = nil
        debugLog("🚫 알람 dismiss 처리: \(alarm.name) (ID: \(alarm.id.uuidString))")
        
        // Analytics 로깅
        AnalyticsService.shared.logAlarmDismissed(alarm: alarm)
    }
    
    // dismiss 상태 초기화 (알람 수정 시 호출)
    func clearDismissedStatus(for alarmId: UUID) {
        dismissedAlarmIds.remove(alarmId)
        debugLog("🔄 알람 dismiss 상태 초기화: \(alarmId.uuidString)")
    }
    
    // 알림이 앱이 포그라운드에 있을 때 표시
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let currentTime = Date()
        debugLog("🔔🔔🔔 willPresent 호출됨 - 알림 도착! (시간: \(currentTime))")
        debugLog("   - 제목: \(notification.request.content.title)")
        debugLog("   - 내용: \(notification.request.content.body)")
        debugLog("   - 사용자 정보: \(notification.request.content.userInfo)")
        debugLog("   - 트리거 타입: \(type(of: notification.request.trigger))")
        
        // 포그라운드에서 커스텀 알림 뷰를 사용하므로 시스템 배너는 숨김
        // 사운드 없음 - 백그라운드 오디오만 사용
        completionHandler([])
        
        // 알람 정보 추출
        if let alarmId = notification.request.content.userInfo["alarmId"] as? String,
           let alarmName = notification.request.content.userInfo["alarmName"] as? String,
           let alarmHour = notification.request.content.userInfo["alarmHour"] as? Int,
           let alarmMinute = notification.request.content.userInfo["alarmMinute"] as? Int,
           let timezoneIdentifier = notification.request.content.userInfo["timezoneIdentifier"] as? String,
           let countryName = notification.request.content.userInfo["countryName"] as? String,
           let countryFlag = notification.request.content.userInfo["countryFlag"] as? String {
            
            debugLog("✅ 알람 정보 추출 성공: \(alarmName)")
            
            // timezoneIdentifier로 City 찾기
            let cityName = City.popularCities.first(where: { $0.timezoneIdentifier == timezoneIdentifier })?.name ?? countryName
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                cityName: cityName,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            // 알림 ID를 로컬 변수로 추출 (데이터 레이스 방지)
            let notificationId = notification.request.identifier
            
            Task { @MainActor in
                // dismiss된 알람인지 확인
                // dismiss된 알람인지 확인 (체인 알림 예약만 막음)
                // activeAlarm은 설정하여 실행 화면이 표시되도록 함
                if self.dismissedAlarmIds.contains(alarm.id) {
                    debugLog("🚫 이미 dismiss된 알람입니다. 체인 알림 예약하지 않음: \(alarm.name)")
                    // activeAlarm은 이미 설정했으므로 실행 화면은 표시됨
                    return
                }
                
                debugLog("📱 activeAlarm 설정 중: \(alarm.name)")
                self.activeAlarm = alarm
                debugLog("✅ activeAlarm 설정 완료")
                
                // 진동 시작
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                
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
                
                debugLog("🔗 다음 체인 알림 예약: chain-\(chainIndex)")
                AlarmScheduler.shared.scheduleChainNotification(for: alarm, chainIndex: chainIndex)
            }
        } else {
            debugLog("❌ 알람 정보 추출 실패")
        }
    }
    
    // 알림을 탭했을 때 (백그라운드에서 알림을 탭하여 앱이 열릴 때)
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        debugLog("🔔 didReceive 호출됨 - 알림 탭됨!")
        debugLog("   - 액션: \(response.actionIdentifier)")
        
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
            
            debugLog("✅ 알람 정보 추출 성공: \(alarmName)")
            
            // timezoneIdentifier로 City 찾기
            let cityName = City.popularCities.first(where: { $0.timezoneIdentifier == timezoneIdentifier })?.name ?? countryName
            
            let alarm = Alarm(
                id: UUID(uuidString: alarmId) ?? UUID(),
                name: alarmName,
                hour: alarmHour,
                minute: alarmMinute,
                timezoneIdentifier: timezoneIdentifier,
                cityName: cityName,
                countryName: countryName,
                countryFlag: countryFlag
            )
            
            // 알림 ID를 로컬 변수로 추출 (데이터 레이스 방지)
            let notificationId = response.notification.request.identifier
            
            // activeAlarm을 먼저 설정하여 ContentView의 onChange가 트리거되도록
            Task { @MainActor in
                debugLog("📱 activeAlarm 설정 중 (didReceive): \(alarm.name)")
                
                // onChange가 확실히 트리거되도록 항상 nil로 리셋한 후 새 알람으로 설정
                // 이렇게 하면 같은 알람이 다시 와도, 다른 알람이 와도 onChange가 확실히 트리거됨
                // 단, 오디오는 계속 재생되도록 유지 (activeAlarm = nil으로 설정해도 오디오는 중단하지 않음)
                let previousAlarm = self.activeAlarm
                let wasPlaying = self.isAudioPlaying // 오디오 재생 상태 저장
                self.activeAlarm = nil
                
                // 약간의 지연을 두어 onChange가 트리거되도록
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
                
                // activeAlarm 설정하여 ContentView의 onChange가 트리거되도록
                // dismiss된 알람이어도 사용자가 푸시를 다시 탭하면 실행 화면이 떠야 함
                self.activeAlarm = alarm
                
                debugLog("✅ activeAlarm 설정 완료: \(alarm.name) (이전: \(previousAlarm?.name ?? "nil"))")
                
                // dismiss된 알람인지 확인 (체인 알림 예약만 막음)
                if self.dismissedAlarmIds.contains(alarm.id) {
                    debugLog("🚫 이미 dismiss된 알람입니다. 체인 알림 예약하지 않음: \(alarm.name)")
                    // 표시된 알림 제거
                    AlarmScheduler.shared.removeDeliveredNotification(for: alarm)
                    // activeAlarm은 이미 설정했으므로 실행 화면은 표시됨
                    // 하지만 체인 알림은 예약하지 않음
                    // 오디오는 이미 재생 중이면 그대로 유지
                    if !wasPlaying {
                        // 오디오가 재생 중이 아니었으면 재생 시작
                        self.startBackgroundAudioPlayback(for: alarm)
                    }
                    return
                }
                
                // 표시된 알림 제거하지 않음 (홈화면으로 가도 푸시 알림이 보이도록)
                // AlarmScheduler.shared.removeDeliveredNotification(for: alarm)
                
                // 진동 시작
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                
                // 백그라운드에서도 연속 사운드 재생 시작 (앱이 실행 중일 때만)
                // 홈버튼으로 홈화면으로 가도 소리가 계속 재생되도록
                // 이미 재생 중이면 그대로 유지, 아니면 재생 시작
                if !wasPlaying {
                    self.startBackgroundAudioPlayback(for: alarm)
                } else {
                    // 이미 재생 중이면 볼륨만 확인
                    self.ensureMaximumVolume()
                }
                
                // 체인 알림 예약: 알림이 도착할 때마다 다음 알림(5초 후) 예약
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
                
                debugLog("🔗 다음 체인 알림 예약: chain-\(chainIndex)")
                AlarmScheduler.shared.scheduleChainNotification(for: alarm, chainIndex: chainIndex)
            }
            
            // completionHandler는 Task 밖에서 즉시 호출 (데이터 레이스 방지)
            // activeAlarm 설정은 Task에서 비동기로 처리되지만, UI 업데이트는 onChange에서 처리됨
            completionHandler()
        } else {
            debugLog("❌ 알람 정보 추출 실패")
            completionHandler()
        }
    }
    
    // 백그라운드에서 연속 사운드 재생 (포그라운드에서도 동일한 플레이어 사용)
    private var backgroundAudioPlayer: AVAudioPlayer?
    private var backgroundAudioTimer: Timer?
    
    // 플레이어가 재생 중인지 확인
    var isAudioPlaying: Bool {
        return backgroundAudioPlayer?.isPlaying ?? false
    }
    
    // 볼륨을 최대로 설정 (백그라운드 전환 시에도 호출)
    func ensureMaximumVolume() {
        if let player = backgroundAudioPlayer {
            player.volume = 1.0
            debugLog("🔊 볼륨 최대값으로 설정: 1.0")
        }
    }
    
    func startBackgroundAudioPlayback(for alarm: Alarm, forceRestart: Bool = false) {
        // forceRestart가 true이면 기존 플레이어를 무조건 정리하고 새로 시작
        if forceRestart {
            debugLog("🔄 강제 재시작 모드 - 기존 플레이어 정리")
            backgroundAudioPlayer?.stop()
            backgroundAudioPlayer = nil
            backgroundAudioTimer?.invalidate()
            backgroundAudioTimer = nil
        } else {
            // 이미 재생 중이면 그대로 유지 (오디오 세션 건드리지 않음)
            if let player = backgroundAudioPlayer, player.isPlaying {
                debugLog("🔊 오디오가 이미 재생 중입니다 (재사용)")
                // 볼륨만 최대값으로 유지
                player.volume = 1.0
                return
            }
            
            // 재생 중이 아니지만 플레이어가 있으면 (멈춰있을 수 있음) 다시 재생 시작
            if let player = backgroundAudioPlayer, !player.isPlaying {
                debugLog("🔊 오디오 플레이어가 있지만 재생 중이 아닙니다. 재생 재개")
                // 오디오 세션 활성화 확인
                setupAudioSession()
                player.volume = 1.0
                player.play()
                debugLog("🔊 오디오 재생 재개 성공")
                // 재생 재개 성공하면 return
                if backgroundAudioPlayer?.isPlaying == true {
                    return
                }
            }
        }
        
        // CAF 형식 우선 확인
        let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "caf") 
            ?? Bundle.main.url(forResource: "alarm", withExtension: "wav")
        
        guard let soundURL = soundURL else {
            debugLog("⚠️ alarm 파일을 찾을 수 없습니다")
            return
        }
        
        do {
            // 오디오 세션 설정 (백그라운드 재생 활성화)
            setupAudioSession()
            
            // 기존 플레이어 정리
            backgroundAudioPlayer?.stop()
            backgroundAudioPlayer = nil
            
            // 오디오 플레이어 생성 및 재생
            backgroundAudioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            backgroundAudioPlayer?.numberOfLoops = -1 // 무한 루프
            backgroundAudioPlayer?.volume = 1.0 // 최대 볼륨 (0.0 ~ 1.0)
            backgroundAudioPlayer?.prepareToPlay() // 재생 준비 (지연 최소화)
            
            // 재생 시작
            let playResult = backgroundAudioPlayer?.play() ?? false
            if !playResult {
                debugLog("⚠️ play() 메서드가 false를 반환했습니다")
            }
            
            // 재생 시작 후 다시 볼륨 확인 (일부 경우 재생 시작 시 볼륨이 리셋될 수 있음)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.backgroundAudioPlayer?.volume = 1.0
                // 재생 상태 재확인
                if let player = self.backgroundAudioPlayer, !player.isPlaying {
                    debugLog("⚠️ 재생 시작 후에도 재생 중이 아닙니다 - 재시도")
                    player.play()
                }
            }
            
            debugLog("🔊 오디오 재생 시작 (백그라운드/포그라운드 공용, 최대 볼륨)")
            
            // 진동 반복 (1초마다)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            backgroundAudioTimer?.invalidate() // 기존 타이머 정리
            backgroundAudioTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            
            // 백그라운드/포그라운드 모두에서 계속 재생되도록 유지
            // dismiss 시 정지됨
        } catch {
            debugLog("❌ 오디오 재생 실패: \(error.localizedDescription)")
            debugLog("   - 에러 코드: \((error as NSError).code)")
            debugLog("   - 에러 도메인: \((error as NSError).domain)")
            
            // 에러 발생 시 한 번만 재시도 (무한 루프 방지)
            // 재시도는 AlarmAlertView에서 처리하도록 함
            debugLog("⚠️ 오디오 재생 실패 - AlarmAlertView에서 재시도 처리 필요")
        }
    }
    
    // 오디오 세션 설정 (백그라운드 재생 활성화)
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            debugLog("✅ 오디오 세션 활성화 완료 (.playback 카테고리)")
        } catch {
            debugLog("❌ 오디오 세션 설정 실패: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundAudioPlayback() {
        backgroundAudioPlayer?.stop()
        backgroundAudioPlayer = nil
        backgroundAudioTimer?.invalidate()
        backgroundAudioTimer = nil
        debugLog("🔇 오디오 재생 정지")
    }
}

