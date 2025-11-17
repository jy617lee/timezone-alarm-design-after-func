//
//  AlarmScheduler.swift
//  TimezoneAlarm
//
//  알람 스케줄링을 위한 로컬 알림 관리
//

import Foundation
@preconcurrency import UserNotifications

final class AlarmScheduler: @unchecked Sendable {
    static nonisolated let shared = AlarmScheduler()
    
    private init() {}
    
    // MARK: - 권한 관리
    
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
    
    // MARK: - 알람 스케줄링
    
    /// 알람 시간대의 시간을 기기 로컬 시간대로 변환하여 스케줄링
    func scheduleAlarm(_ alarm: Alarm) {
        debugLog("🎯 scheduleAlarm 호출됨: \(alarm.name)")
        
        // 기존 알림 제거
        cancelAlarm(alarm)
        
        guard let alarmTimezone = TimeZone(identifier: alarm.timezoneIdentifier) else {
            debugLog("⚠️ 시간대를 찾을 수 없음: \(alarm.timezoneIdentifier)")
            return
        }
        
        let content = createNotificationContent(for: alarm)
        let now = Date()
        
        // 알람 타입에 따라 스케줄링
        if !alarm.selectedWeekdays.isEmpty {
            scheduleRepeatingAlarm(alarm: alarm, alarmTimezone: alarmTimezone, content: content, now: now)
        } else if let selectedDate = alarm.selectedDate {
            scheduleDateAlarm(alarm: alarm, selectedDate: selectedDate, alarmTimezone: alarmTimezone, content: content, now: now)
        } else {
            scheduleSingleAlarm(alarm: alarm, alarmTimezone: alarmTimezone, content: content, now: now)
        }
    }
    
    // MARK: - 타임존 변환 헬퍼
    
    /// 알람 시간대의 시간을 로컬 시간대 DateComponents로 변환
    /// - Parameters:
    ///   - alarm: 알람 정보
    ///   - alarmTimezone: 알람이 설정된 시간대
    ///   - date: 기준 날짜 (알람 시간을 만들기 위한 날짜)
    /// - Returns: 로컬 시간대 DateComponents (nil이면 변환 실패)
    private func convertToLocalComponents(alarm: Alarm, alarmTimezone: TimeZone, date: Date) -> DateComponents? {
        // 알람 시간대의 Calendar 생성
        var alarmCalendar = Calendar.current
        alarmCalendar.timeZone = alarmTimezone
        
        // 알람 시간대에서 DateComponents 생성
        var alarmComponents = alarmCalendar.dateComponents([.year, .month, .day], from: date)
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        
        // 알람 시간대에서 Date 생성 (UTC 기준)
        guard let alarmTime = alarmCalendar.date(from: alarmComponents) else {
            return nil
        }
        
        // 로컬 시간대 Calendar로 변환
        let localCalendar = Calendar.current
        var localComponents = localCalendar.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: alarmTime)
        localComponents.second = 0
        
        return localComponents
    }
    
    // MARK: - 알람 타입별 스케줄링
    
    /// 반복 요일 알람 스케줄링
    private func scheduleRepeatingAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, now: Date) {
        let weekdayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
        
        for alarmWeekday in alarm.selectedWeekdays {
            // 알람 시간대에서 다음 해당 요일 찾기
            let targetDate = findNextWeekdayInTimezone(weekday: alarmWeekday, timezone: alarmTimezone, from: now)
            
            // 알람 시간대의 시간을 로컬 시간대로 변환
            guard let localComponents = convertToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: targetDate) else {
                debugLog("⚠️ 요일 알람 시간 생성 실패: weekday=\(alarmWeekday)")
                continue
            }
            
            // 로컬 시간대의 weekday 사용 (변환된 요일)
            // UNCalendarNotificationTrigger는 로컬 시간대의 weekday를 사용하므로
            // 변환된 localComponents의 weekday를 그대로 사용
            let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: true)
            let identifier = "\(alarm.id.uuidString)-weekday-\(alarmWeekday)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            addNotificationRequest(request) { success in
                if success {
                    let localWeekday = localComponents.weekday ?? alarmWeekday
                    debugLog("✅ 반복 알람 스케줄링 성공: \(alarm.name) - 알람 시간대 \(weekdayNames[alarmWeekday])요일 → 로컬 시간대 \(weekdayNames[localWeekday])요일")
                    
                    // 반복 알람도 사용자가 끌 때까지 계속 울리도록 체인 알림 예약
                    // (repeats: true는 매주 같은 시간에 알림이 오는 것이지, 한 번 울리고 끝나는 것이 아님)
                    self.schedulePreChainNotifications(for: alarm, baseIdentifier: identifier, baseComponents: localComponents)
                } else {
                    debugLog("❌ 반복 알람 스케줄링 실패 (요일 \(alarmWeekday))")
                }
            }
        }
    }
    
    /// 특정 날짜 알람 스케줄링
    private func scheduleDateAlarm(alarm: Alarm, selectedDate: Date, alarmTimezone: TimeZone, content: UNMutableNotificationContent, now: Date) {
        guard let localComponents = convertToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: selectedDate) else {
            debugLog("⚠️ 날짜 알람 시간 생성 실패")
            return
        }
        
        // 과거 날짜면 스케줄링하지 않음
        if let alarmDate = Calendar.current.date(from: localComponents), alarmDate <= now {
            debugLog("⚠️ 과거 날짜 알람은 스케줄링하지 않음: \(alarm.name)")
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: false)
        let identifier = alarm.id.uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        addNotificationRequest(request) { success in
            if success {
                debugLog("✅ 날짜 알람 스케줄링 성공: \(alarm.name)")
                
                // 백그라운드에서도 알림이 계속 울리도록 체인 알림 미리 예약
                self.schedulePreChainNotifications(for: alarm, baseIdentifier: identifier, baseComponents: localComponents)
            } else {
                debugLog("❌ 날짜 알람 스케줄링 실패")
            }
        }
    }
    
    /// 단일 알람 스케줄링
    private func scheduleSingleAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, now: Date) {
        // 알람 시간이 이미 지났다면 다음 날로
        let targetDate = findNextAlarmDate(alarm: alarm, alarmTimezone: alarmTimezone, from: now)
        
        debugLog("🔔 단일 알람 스케줄링 시작: \(alarm.name)")
        debugLog("   - 알람 시간대: \(alarmTimezone.identifier)")
        debugLog("   - 알람 시간: \(alarm.hour):\(String(format: "%02d", alarm.minute))")
        debugLog("   - 타겟 날짜 (알람 시간대 기준): \(targetDate)")
        
        guard let localComponents = convertToLocalComponents(alarm: alarm, alarmTimezone: alarmTimezone, date: targetDate) else {
            debugLog("❌ 알람 시간 생성 실패 - convertToLocalComponents 반환 nil")
            return
        }
        
        if let nextDate = Calendar.current.date(from: localComponents) {
            debugLog("   - 알람 실행 예정 (로컬 시간): \(nextDate)")
            debugLog("   - 로컬 컴포넌트: year=\(localComponents.year ?? -1), month=\(localComponents.month ?? -1), day=\(localComponents.day ?? -1), hour=\(localComponents.hour ?? -1), minute=\(localComponents.minute ?? -1)")
        } else {
            debugLog("❌ 로컬 컴포넌트에서 날짜 생성 실패")
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: false)
        let identifier = alarm.id.uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        debugLog("   - 알림 요청 생성: identifier=\(identifier)")
        
        addNotificationRequest(request) { success in
            if success {
                debugLog("✅✅✅ 메인 알람 스케줄링 성공: \(alarm.name)")
                debugLog("   - 알림 ID: \(identifier)")
                debugLog("   - 예정 시간: \(Calendar.current.date(from: localComponents)?.description ?? "알 수 없음")")
                
                // 백그라운드에서도 알림이 계속 울리도록 체인 알림 미리 예약
                self.schedulePreChainNotifications(for: alarm, baseIdentifier: identifier, baseComponents: localComponents)
            } else {
                debugLog("❌❌❌ 메인 알람 스케줄링 실패: \(alarm.name)")
            }
        }
    }
    
    // MARK: - 날짜/요일 찾기 헬퍼
    
    /// 알람 시간대에서 다음 해당 요일 찾기
    private func findNextWeekdayInTimezone(weekday: Int, timezone: TimeZone, from date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        // 알람 시간대에서 현재 요일 확인
        let todayComponents = calendar.dateComponents([.weekday], from: date)
        let todayWeekday = todayComponents.weekday ?? 1
        
        if todayWeekday == weekday {
            // 오늘이 해당 요일이면 오늘 사용
            return date
        }
        
        // 다음 해당 요일까지의 일수 계산
        var daysToAdd = weekday - todayWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // 다음 주로
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }
    
    /// 다음 알람 날짜 찾기 (단일 알람용)
    private func findNextAlarmDate(alarm: Alarm, alarmTimezone: TimeZone, from date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = alarmTimezone
        
        // 알람 시간대에서 현재 날짜/시간 가져오기
        // date는 UTC이지만, calendar.timeZone이 alarmTimezone이므로 알람 시간대에서 해석됨
        let alarmTimezoneComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        // 알람 시간대의 현재 시간을 UTC Date로 변환 (비교용)
        guard let alarmTimezoneNow = calendar.date(from: alarmTimezoneComponents) else {
            debugLog("⚠️ findNextAlarmDate: 알람 시간대 현재 시간 생성 실패")
            return date
        }
        
        // 알람 시간 설정 (알람 시간대의 오늘 날짜에 알람 시간)
        var alarmComponents = alarmTimezoneComponents
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        
        guard let todayAlarmTime = calendar.date(from: alarmComponents) else {
            debugLog("⚠️ findNextAlarmDate: 오늘 알람 시간 생성 실패")
            return date
        }
        
        debugLog("🔍 findNextAlarmDate:")
        debugLog("   - 기준 시간 (UTC): \(date)")
        debugLog("   - 알람 시간대 기준 현재: \(alarmTimezoneNow)")
        debugLog("   - 알람 시간대 기준 오늘 알람 시간: \(todayAlarmTime)")
        debugLog("   - 알람 시간이 지났는지: \(todayAlarmTime <= alarmTimezoneNow)")
        
        // 알람 시간이 이미 지났다면 다음 날로
        if todayAlarmTime <= alarmTimezoneNow {
            // 다음 날의 알람 시간 계산
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: todayAlarmTime) {
                var nextDayComponents = calendar.dateComponents([.year, .month, .day], from: nextDay)
                nextDayComponents.hour = alarm.hour
                nextDayComponents.minute = alarm.minute
                nextDayComponents.second = 0
                
                if let nextAlarmTime = calendar.date(from: nextDayComponents) {
                    debugLog("   - 다음 날로 이동: \(nextAlarmTime)")
                    return nextAlarmTime
                }
            }
            debugLog("   - 다음 날 계산 실패, 오늘 사용")
            return todayAlarmTime
        }
        
        debugLog("   - 오늘 알람 시간 사용: \(todayAlarmTime)")
        return todayAlarmTime
    }
    
    // MARK: - 알림 요청 추가
    
    /// 알림 요청 추가 (권한 확인 포함)
    private func addNotificationRequest(_ request: UNNotificationRequest, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // 🔧 상세한 알림 설정 로그 (사용자 요청)
            debugLog("🔧 알림 설정 상세:")
            debugLog("   - auth: \(settings.authorizationStatus.rawValue)")
            debugLog("   - alert: \(settings.alertSetting.rawValue)")
            debugLog("   - sound: \(settings.soundSetting.rawValue) ⚠️ 이게 .enabled(0) 아니면 소리 안 남!")
            debugLog("   - notificationCenter: \(settings.notificationCenterSetting.rawValue)")
            debugLog("   - lockScreen: \(settings.lockScreenSetting.rawValue)")
            
            guard settings.authorizationStatus == .authorized else {
                debugLog("❌ 알림 권한이 없습니다. 권한 상태: \(settings.authorizationStatus.rawValue)")
                completion(false)
                return
            }
            
            // soundSetting 확인 (0=notSupported, 1=disabled, 2=enabled)
            if settings.soundSetting == .enabled {
                debugLog("✅ soundSetting: .enabled (정상)")
            } else {
                debugLog("⚠️ soundSetting: \(settings.soundSetting.rawValue) (.enabled 아님)")
            }
            
            // 알림 사운드 정보 로그
            if let sound = request.content.sound {
                debugLog("🔊 알림 사운드 설정 확인: \(sound)")
            } else {
                debugLog("⚠️ 알림 사운드가 설정되지 않음!")
            }
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    debugLog("❌ 알림 추가 실패: \(error.localizedDescription)")
                    completion(false)
                } else {
                    debugLog("✅ 알림 추가 성공 - ID: \(request.identifier), 사운드: \(request.content.sound != nil ? "설정됨" : "없음")")
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - 알림 콘텐츠 생성
    
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.name
        content.body = "\(alarm.formattedTime) - \(alarm.countryFlag) \(alarm.countryName)"
        
        // 알람 사운드 설정
        // 백그라운드에서도 제대로 울리도록 확장자를 포함한 파일명 사용
        if Bundle.main.url(forResource: "alarm", withExtension: "caf") != nil {
            // 백그라운드에서 제대로 울리려면 확장자를 포함해야 함
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.caf"))
            debugLog("   - 커스텀 알람 사운드 사용: alarm.caf")
        } else if Bundle.main.url(forResource: "alarm", withExtension: "wav") != nil {
            // WAV 폴백
            content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
            debugLog("   - 커스텀 알람 사운드 사용: alarm.wav")
        } else {
            // 기본 사운드 사용
            content.sound = .default
            debugLog("   - 기본 알람 사운드 사용 (.default)")
        }
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
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
    
    // MARK: - 체인 알림
    
    /// 백그라운드에서도 알림이 계속 울리도록 메인 알림과 함께 체인 알림을 미리 예약
    /// - Parameters:
    ///   - alarm: 알람 정보
    ///   - baseIdentifier: 메인 알림의 identifier
    ///   - baseComponents: 메인 알림의 DateComponents
    private func schedulePreChainNotifications(for alarm: Alarm, baseIdentifier: String, baseComponents: DateComponents) {
        guard let baseDate = Calendar.current.date(from: baseComponents) else {
            debugLog("⚠️ 체인 알림 예약 실패: 기준 날짜 생성 실패")
            return
        }
        
        // 최대 20개의 체인 알림 예약 (총 100초간, 5초 간격)
        let maxChainCount = 20
        let chainInterval: TimeInterval = 5.0
        
        for chainIndex in 0..<maxChainCount {
            let chainDate = baseDate.addingTimeInterval(chainInterval * Double(chainIndex + 1))
            let chainComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: chainDate)
            
            let content = createNotificationContent(for: alarm)
            let trigger = UNCalendarNotificationTrigger(dateMatching: chainComponents, repeats: false)
            let identifier = "\(baseIdentifier)-chain-\(chainIndex)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            addNotificationRequest(request) { success in
                if success {
                    debugLog("✅ 체인 알림 미리 예약 성공: \(alarm.name) (chain-\(chainIndex), 시간: \(chainDate))")
                } else {
                    debugLog("❌ 체인 알림 미리 예약 실패 (chain-\(chainIndex))")
                }
            }
        }
        
        debugLog("🔗 백그라운드 체인 알림 \(maxChainCount)개 미리 예약 완료: \(alarm.name)")
    }
    
    /// 동적으로 체인 알림 예약 (willPresent/didReceive에서 호출)
    func scheduleChainNotification(for alarm: Alarm, chainIndex: Int) {
        let content = createNotificationContent(for: alarm)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        let identifier = "\(alarm.id.uuidString)-chain-\(chainIndex)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        addNotificationRequest(request) { success in
            if success {
                debugLog("✅ 체인 알림 스케줄링 성공: \(alarm.name) (chain-\(chainIndex))")
            } else {
                debugLog("❌ 체인 알림 스케줄링 실패 (chain-\(chainIndex))")
            }
        }
    }
    
    // MARK: - 알람 취소
    
    func cancelAlarm(_ alarm: Alarm) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.hasPrefix(alarm.id.uuidString) }
                .map { $0.identifier }
            
            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                debugLog("🚫 알람 취소: \(alarm.name) (ID: \(alarm.id.uuidString), 개수: \(identifiers.count))")
            } else {
                debugLog("🚫 알람 취소: \(alarm.name) - 취소할 알림 없음")
            }
        }
    }
    
    func removeDeliveredNotification(for alarm: Alarm) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiers = notifications
                .filter { $0.request.identifier.hasPrefix(alarm.id.uuidString) }
                .map { $0.request.identifier }
            
            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
                debugLog("🗑️ 표시된 알림 제거: \(alarm.name) (개수: \(identifiers.count))")
            }
        }
    }
    
    // MARK: - 앱 시작 시 재스케줄링 확인
    
    /// 앱 시작 시 스케줄링 확인 및 필요시 재스케줄링
    /// - Parameters:
    ///   - alarms: 저장된 알람 목록
    ///   - completion: 완료 콜백 (재스케줄링된 알람 개수)
    func verifyAndRescheduleIfNeeded(alarms: [Alarm], completion: @escaping (Int) -> Void) {
        let enabledAlarms = alarms.filter { $0.isEnabled }
        
        guard !enabledAlarms.isEmpty else {
            debugLog("📋 활성화된 알람이 없습니다")
            completion(0)
            return
        }
        
        // 현재 스케줄링된 알림 가져오기
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let scheduledAlarmIds = Set(requests.compactMap { request -> UUID? in
                // 알림 ID에서 알람 ID 추출 (weekday-, chain- 접두사 제거)
                let identifier = request.identifier
                if let range = identifier.range(of: "-") {
                    let alarmIdString = String(identifier[..<range.lowerBound])
                    return UUID(uuidString: alarmIdString)
                }
                return UUID(uuidString: identifier)
            })
            
            // 스케줄링이 필요한 알람 찾기
            let alarmsToReschedule = enabledAlarms.filter { alarm in
                !scheduledAlarmIds.contains(alarm.id)
            }
            
            if alarmsToReschedule.isEmpty {
                debugLog("✅ 모든 알람이 정상적으로 스케줄링되어 있습니다")
                completion(0)
            } else {
                debugLog("🔄 재스케줄링 필요한 알람: \(alarmsToReschedule.count)개")
                for alarm in alarmsToReschedule {
                    debugLog("   - \(alarm.name)")
                    self.scheduleAlarm(alarm)
                }
                completion(alarmsToReschedule.count)
            }
        }
    }
}

