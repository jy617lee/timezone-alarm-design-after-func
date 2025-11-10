//
//  AlarmScheduler.swift
//  TimezoneAlarm
//
//  알람 스케줄링을 위한 로컬 알림 관리
//

import Foundation
import UserNotifications

final class AlarmScheduler: @unchecked Sendable {
    static nonisolated let shared = AlarmScheduler()
    
    private init() {}
    
    // 알람 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            debugLog("🔔 알림 권한 요청 결과: \(granted ? "허용됨" : "거부됨")")
            return granted
        } catch {
            debugLog("❌ 알람 권한 요청 실패: \(error)")
            return false
        }
    }
    
    // 알람 시간대로 변환하여 스케줄링
    // 예: 한국 시간 6시 PM으로 설정 → 기기가 미국에 있으면 미국 새벽 4시에 울림
    // 중요: 알람 생성 시점의 로컬 시간대가 아닌, 알람이 실제로 울릴 때의 로컬 시간대를 사용
    // 사용자가 다른 국가로 이동해도 정확한 시간에 알람이 울림
    func scheduleAlarm(_ alarm: Alarm) {
        debugLog("🎯 scheduleAlarm 호출됨: \(alarm.name)")
        
        // 기존 알림 제거
        cancelAlarm(alarm)
        
        let content = createNotificationContent(for: alarm)
        debugLog("📦 알림 콘텐츠 생성 완료")
        
        // 알람이 설정된 국가의 시간대
        guard let alarmTimezone = TimeZone(identifier: alarm.timezoneIdentifier) else {
            debugLog("⚠️ 시간대를 찾을 수 없음: \(alarm.timezoneIdentifier)")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // 반복 요일이 있는 경우
        if !alarm.selectedWeekdays.isEmpty {
            scheduleRepeatingAlarm(alarm: alarm, alarmTimezone: alarmTimezone, content: content, calendar: calendar, now: now)
        } else if let selectedDate = alarm.selectedDate {
            // 특정 날짜 알람
            scheduleDateAlarm(alarm: alarm, selectedDate: selectedDate, alarmTimezone: alarmTimezone, content: content, calendar: calendar, now: now)
        } else {
            // 단일 알람
            scheduleSingleAlarm(alarm: alarm, alarmTimezone: alarmTimezone, content: content, calendar: calendar, now: now)
        }
    }
    
    // 공통 헬퍼: 알람 시간대의 시간을 로컬 시간대 DateComponents로 변환
    private func convertAlarmTimeToLocalComponents(alarm: Alarm, alarmTimezone: TimeZone, date: Date, weekday: Int? = nil) -> DateComponents? {
        let calendar = Calendar.current
        var alarmComponents = calendar.dateComponents(in: alarmTimezone, from: date)
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        if let weekday = weekday {
            alarmComponents.weekday = weekday
        }
        alarmComponents.timeZone = alarmTimezone
        
        guard let alarmTimeUTC = calendar.date(from: alarmComponents) else { return nil }
        
        // UTC를 로컬 시간대로 변환
        var localComponents = calendar.dateComponents(in: TimeZone.current, from: alarmTimeUTC)
        localComponents.second = 0
        return localComponents
    }
    
    // 반복 요일 알람 스케줄링
    private func scheduleRepeatingAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        let weekdayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
        
        for weekday in alarm.selectedWeekdays {
            // 알람 시간대에서 다음 해당 요일 찾기
            var targetDate = now
            if let localComponents = convertAlarmTimeToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: now, weekday: weekday) {
                // 오늘 해당 요일인지 확인
                let todayComponents = calendar.dateComponents(in: alarmTimezone, from: now)
                if todayComponents.weekday == weekday {
                    // 오늘이 해당 요일이면 오늘 시간 사용
                    targetDate = now
                } else {
                    // 다음 주 해당 요일로
                    targetDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
                }
            } else {
                // 변환 실패 시 다음 주로
                targetDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
            }
            
            guard let localComponents = convertAlarmTimeToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: targetDate, weekday: weekday) else {
                
                debugLog("⚠️ 요일 알람 시간 생성 실패: weekday=\(weekday)")
                
                continue
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
            let identifier = "\(alarm.id.uuidString)-weekday-\(weekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                
                if let error = error {
                    debugLog("❌ 반복 알람 스케줄링 실패 (요일 \(weekday)): \(error.localizedDescription)")
                } else {
                    debugLog("✅ 반복 알람 스케줄링 성공: \(alarm.name) - 매주 \(weekdayNames[weekday])요일")
                }
                
            }
        }
    }
    
    // 특정 날짜 알람 스케줄링
    private func scheduleDateAlarm(alarm: Alarm, selectedDate: Date, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        guard let localComponents = convertAlarmTimeToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: selectedDate) else {
            
            debugLog("⚠️ 날짜 알람 시간 생성 실패")
            
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            
            if let error = error {
                debugLog("❌ 날짜 알람 스케줄링 실패: \(error.localizedDescription)")
            } else {
                debugLog("✅ 날짜 알람 스케줄링 성공: \(alarm.name)")
            }
            
        }
    }
    
    // 단일 알람 스케줄링
    private func scheduleSingleAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        guard let localComponents = convertAlarmTimeToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: now) else {
            
            debugLog("⚠️ 알람 시간 생성 실패")
            
            return
        }
        
        // 알람 시간이 이미 지났다면 다음 날로
        var targetDate = now
        var alarmComponents = calendar.dateComponents(in: alarmTimezone, from: now)
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        alarmComponents.timeZone = alarmTimezone
        
        if let alarmTimeUTC = calendar.date(from: alarmComponents), alarmTimeUTC <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        guard let finalComponents = convertAlarmTimeToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: targetDate) else {
            
            debugLog("⚠️ 알람 시간 생성 실패")
            
            return
        }
        
        
        debugLog("🔔 단일 알람 스케줄링 시작: \(alarm.name)")
        debugLog("   - 현재 시간: \(now)")
        if let nextDate = calendar.date(from: finalComponents) {
            debugLog("   - 알람 실행 예정: \(nextDate)")
        }
        
        
        // 권한 확인
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            
            debugLog("📱 알림 권한 상태: \(settings.authorizationStatus.rawValue)")
            
            
            guard settings.authorizationStatus == .authorized else {
                
                debugLog("❌ 알림 권한이 없습니다. 권한 상태: \(settings.authorizationStatus.rawValue)")
                
                return
            }
            
            // 첫 번째 알림 스케줄링
            let trigger = UNCalendarNotificationTrigger(dateMatching: finalComponents, repeats: false)
            let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
            
            
            if let nextTriggerDate = trigger.nextTriggerDate() {
                debugLog("   - 트리거 다음 실행 시간: \(nextTriggerDate)")
                let timeUntilTrigger = nextTriggerDate.timeIntervalSinceNow
                debugLog("   - 남은 시간: \(String(format: "%.2f", timeUntilTrigger))초")
            }
            
            
            UNUserNotificationCenter.current().add(request) { error in
                
                if let error = error {
                    debugLog("❌ 알람 스케줄링 실패: \(error.localizedDescription)")
                } else {
                    debugLog("✅ 알람 스케줄링 성공: \(alarm.name)")
                }
                
            }
        }
    }
    
    // 알림 콘텐츠 생성
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.name
        content.body = "\(alarm.formattedTime) - \(alarm.countryFlag) \(alarm.countryName)"
        
        // 알람 사운드 설정
        // 백그라운드에서도 소리가 나도록 커스텀 사운드 사용
        // 백그라운드 오디오와 함께 사용하여 연속 재생 효과
        if Bundle.main.url(forResource: "alarm", withExtension: "wav") != nil {
            // 커스텀 사운드 파일 사용 (28.86초, 30초 이하 - 백그라운드 호환)
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
            
            debugLog("   - 커스텀 알람 사운드 사용: alarm.wav (백그라운드 호환)")
            
        } else {
            // 폴백: 기본 알람 사운드
            content.sound = .default
            
            debugLog("   ⚠️ alarm.wav 파일을 찾을 수 없어 기본 사운드 사용")
            
        }
        
        // iOS 15+ Time Sensitive 알림 설정
        // Do Not Disturb를 우회하고 더 눈에 띄게 표시됨
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            
            debugLog("   - interruptionLevel: .timeSensitive 설정됨")
            
        }
        
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "alarmName": alarm.name,
            "alarmHour": alarm.hour,
            "alarmMinute": alarm.minute,
            "timezoneIdentifier": alarm.timezoneIdentifier,
            "countryName": alarm.countryName,
            "countryFlag": alarm.countryFlag
        ]
        content.categoryIdentifier = "ALARM_CATEGORY"
        return content
    }
    
    // 체인 알림 예약 (10초 간격으로 다음 알림 예약)
    func scheduleChainNotification(for alarm: Alarm, chainIndex: Int) {
        let content = createNotificationContent(for: alarm)
        
        // 10초 후에 울리도록 설정
        let chainInterval: TimeInterval = 10.0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: chainInterval, repeats: false)
        
        // 체인 알림 ID: {alarm.id}-chain-{index}
        let identifier = "\(alarm.id.uuidString)-chain-\(chainIndex)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            
            if let error = error {
                debugLog("❌ 체인 알림 스케줄링 실패 (chain-\(chainIndex)): \(error.localizedDescription)")
            } else {
                debugLog("✅ 체인 알림 스케줄링 성공: \(alarm.name) (chain-\(chainIndex))")
            }
            
        }
    }
    
    // 알람 취소 (대기 중인 알림 제거 - 체인 알림 포함)
    func cancelAlarm(_ alarm: Alarm) {
        // 실제로 대기 중인 모든 알림을 가져와서 해당 알람의 모든 알림을 찾아서 취소
        // 이렇게 하면 체인 알림이 몇 개든 상관없이 모두 취소됨
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            var identifiers: [String] = []
            
            // 알람 ID로 시작하는 모든 알림 찾기
            for request in requests {
                if request.identifier.hasPrefix(alarm.id.uuidString) {
                    identifiers.append(request.identifier)
                }
            }
            
            // 찾은 알림들을 모두 취소
            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                
                debugLog("🚫 알람 취소: \(alarm.name) (ID: \(alarm.id.uuidString))")
                debugLog("   취소할 알림 ID 개수: \(identifiers.count)")
                debugLog("   취소된 알림 ID: \(identifiers.prefix(10).map { $0 })\(identifiers.count > 10 ? " ... 외 \(identifiers.count - 10)개" : "")")
                
            } else {
                
                debugLog("🚫 알람 취소: \(alarm.name) (ID: \(alarm.id.uuidString)) - 취소할 알림 없음")
                
            }
            
            // 취소 확인 (비동기, 로깅용)
            
            UNUserNotificationCenter.current().getPendingNotificationRequests { remainingRequests in
                let remaining = remainingRequests.filter { req in
                    req.identifier.hasPrefix(alarm.id.uuidString)
                }
                if !remaining.isEmpty {
                    debugLog("⚠️ 알람 취소 후에도 남은 알림이 있습니다: \(remaining.map { $0.identifier })")
                } else {
                    debugLog("✅ 알람 취소 완료 - 모든 알림이 제거되었습니다")
                }
            }
            
        }
    }
    
    // 이미 표시된 알림 제거 (dismiss 시 푸시 알림도 제거 - 체인 알림 포함)
    func removeDeliveredNotification(for alarm: Alarm) {
        // 먼저 모든 표시된 알림을 가져와서 해당 알람의 모든 알림 ID 수집
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            var identifiers: [String] = []
            
            // 알람 ID로 시작하는 모든 알림 찾기
            for notification in notifications {
                if notification.request.identifier.hasPrefix(alarm.id.uuidString) {
                    identifiers.append(notification.request.identifier)
                }
            }
            
            // 단일 알람 ID도 추가 (혹시 모를 경우를 위해)
            if !identifiers.contains(alarm.id.uuidString) {
                identifiers.append(alarm.id.uuidString)
            }
            
            // 반복 알람의 경우 모든 요일별 알림 ID 추가
            for weekday in alarm.selectedWeekdays {
                let weekdayId = "\(alarm.id.uuidString)-weekday-\(weekday)"
                if !identifiers.contains(weekdayId) {
                    identifiers.append(weekdayId)
                }
            }
            
            // 체인 알림 ID 패턴 추가 (모든 체인 인덱스)
            // 최대 100개까지 체인 알림이 있을 수 있다고 가정
            for i in 0..<100 {
                let chainId = "\(alarm.id.uuidString)-chain-\(i)"
                if !identifiers.contains(chainId) {
                    identifiers.append(chainId)
                }
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            
            debugLog("🗑️ 표시된 알림 제거: \(alarm.name) (ID: \(alarm.id.uuidString), 개수: \(identifiers.count))")
            
        }
    }
    
    // 모든 대기 중인 알림 제거 (디버깅용)
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        debugLog("🗑️ 모든 대기 중인 알림 제거 완료")
        
    }
    
    // 모든 알람의 알림 취소 (앱 시작 시 중복 방지용)
    func cancelAllAlarms(_ alarms: [Alarm]) {
        
        debugLog("🗑️ 모든 알람의 알림 취소 시작 (총 \(alarms.count)개)")
        
        for alarm in alarms {
            cancelAlarm(alarm)
        }
    }
}

