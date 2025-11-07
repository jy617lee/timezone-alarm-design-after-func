//
//  AlarmScheduler.swift
//  TimezoneAlarm
//
//  테스트용: 5초 후 알람 실행을 위한 로컬 알림 스케줄링
//

import Foundation
import UserNotifications

final class AlarmScheduler: @unchecked Sendable {
    static nonisolated let shared = AlarmScheduler()
    
    private init() {}
    
    // 알람 권한 요청
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("알람 권한 요청 실패: \(error)")
            return false
        }
    }
    
    // 테스트용: 알람 시간대로 변환하여 스케줄링
    // 예: 한국 시간 6시 PM으로 설정 → 기기가 미국에 있으면 미국 새벽 4시에 울림
    // 중요: 알람 생성 시점의 로컬 시간대가 아닌, 알람이 실제로 울릴 때의 로컬 시간대를 사용
    // 사용자가 다른 국가로 이동해도 정확한 시간에 알람이 울림
    func scheduleTestAlarm(_ alarm: Alarm) {
        // 기존 알림 제거
        cancelAlarm(alarm)
        
        let content = createNotificationContent(for: alarm)
        
        // 알람이 설정된 국가의 시간대
        guard let alarmTimezone = TimeZone(identifier: alarm.timezoneIdentifier) else {
            print("⚠️ 시간대를 찾을 수 없음: \(alarm.timezoneIdentifier)")
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
            // 단일 알람 (테스트용: 5초 후 또는 실제 알람 시간)
            scheduleSingleAlarm(alarm: alarm, alarmTimezone: alarmTimezone, content: content, calendar: calendar, now: now)
        }
    }
    
    // 반복 요일 알람 스케줄링 (매주 금요일 등)
    private func scheduleRepeatingAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        // 각 선택된 요일마다 반복 알람 생성
        for weekday in alarm.selectedWeekdays {
            // 1. 알람 시간대에서 해당 요일의 알람 시간 계산
            // 알람 시간대의 현재 시간에서 다음 해당 요일 찾기
            var alarmComponents = DateComponents()
            alarmComponents.hour = alarm.hour
            alarmComponents.minute = alarm.minute
            alarmComponents.second = 0
            alarmComponents.weekday = weekday // 1=일요일, 2=월요일, ..., 6=금요일, 7=토요일
            
            // 알람 시간대의 현재 시간
            let alarmTimezoneNow = calendar.dateComponents(in: alarmTimezone, from: now)
            
            // 알람 시간대에서 다음 해당 요일 찾기
            var nextWeekdayComponents = DateComponents()
            nextWeekdayComponents.year = alarmTimezoneNow.year
            nextWeekdayComponents.month = alarmTimezoneNow.month
            nextWeekdayComponents.day = alarmTimezoneNow.day
            nextWeekdayComponents.hour = alarm.hour
            nextWeekdayComponents.minute = alarm.minute
            nextWeekdayComponents.second = 0
            nextWeekdayComponents.weekday = weekday
            nextWeekdayComponents.timeZone = alarmTimezone
            
            // 알람 시간대에서 해당 요일의 알람 시간을 UTC로 변환
            if let alarmTimeInTimezone = calendar.date(from: nextWeekdayComponents) {
                // 오늘이 해당 요일이면 오늘 시간 사용, 아니면 다음 주
                let targetTime = alarmTimeInTimezone > now ? alarmTimeInTimezone : calendar.date(byAdding: .weekOfYear, value: 1, to: alarmTimeInTimezone) ?? alarmTimeInTimezone
                scheduleRepeatingWeekdayAlarm(alarm: alarm, weekday: weekday, alarmTimeUTC: targetTime, content: content, alarmTimezone: alarmTimezone)
            } else {
                // 오늘 해당 요일이 아니면 다음 주로
                var nextWeekComponents = nextWeekdayComponents
                if let tempDate = calendar.date(from: nextWeekdayComponents),
                   let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: tempDate) {
                    nextWeekComponents = calendar.dateComponents(in: alarmTimezone, from: nextWeek)
                    nextWeekComponents.hour = alarm.hour
                    nextWeekComponents.minute = alarm.minute
                    nextWeekComponents.second = 0
                    nextWeekComponents.weekday = weekday
                    nextWeekComponents.timeZone = alarmTimezone
                } else {
                    // 다음 주 계산 실패 시 현재 시간 기준으로 다음 주 계산
                    if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) {
                        nextWeekComponents = calendar.dateComponents(in: alarmTimezone, from: nextWeek)
                        nextWeekComponents.hour = alarm.hour
                        nextWeekComponents.minute = alarm.minute
                        nextWeekComponents.second = 0
                        nextWeekComponents.weekday = weekday
                        nextWeekComponents.timeZone = alarmTimezone
                    }
                }
                guard let alarmTimeUTC = calendar.date(from: nextWeekComponents) else {
                    print("⚠️ 요일 알람 시간 생성 실패: weekday=\(weekday)")
                    continue
                }
                scheduleRepeatingWeekdayAlarm(alarm: alarm, weekday: weekday, alarmTimeUTC: alarmTimeUTC, content: content, alarmTimezone: alarmTimezone)
            }
        }
    }
    
    // 반복 요일 알람 스케줄링 (각 요일별)
    // 중요: 알람 시간대의 요일/시간을 항상 유지
    // 예: 한국 시간 매주 수요일 6시 PM → 미국에 가도 한국 시간 수요일 6시 PM에 울림
    // 해결: 알람 시간대의 요일/시간을 UTC로 저장하고, 현재 로컬 시간대로 변환하여 스케줄링
    // 타임존이 바뀔 때마다 재스케줄링하여 항상 알람 시간대 기준으로 정확히 울림
    private func scheduleRepeatingWeekdayAlarm(alarm: Alarm, weekday: Int, alarmTimeUTC: Date, content: UNMutableNotificationContent, alarmTimezone: TimeZone) {
        let calendar = Calendar.current
        let localTimezone = TimeZone.current
        
        // 알람 시간대의 요일/시간을 UTC로 저장 (alarmTimeUTC)
        // 현재 로컬 시간대에서 이 UTC 시간이 몇 시/요일인지 계산
        let localComponents = calendar.dateComponents(in: localTimezone, from: alarmTimeUTC)
        
        // 로컬 시간대에서 알람이 울려야 할 요일/시간
        // 알람 시간대의 요일/시간(UTC)을 현재 로컬 시간대로 변환
        var localAlarmComponents = DateComponents()
        localAlarmComponents.weekday = localComponents.weekday // 로컬 시간대의 요일
        localAlarmComponents.hour = localComponents.hour // 로컬 시간대의 시간
        localAlarmComponents.minute = localComponents.minute
        localAlarmComponents.second = 0
        
        // UNCalendarNotificationTrigger는 로컬 시간대를 사용
        // 타임존이 바뀔 때마다 재스케줄링하면 항상 알람 시간대 기준으로 정확히 울림
        let trigger = UNCalendarNotificationTrigger(dateMatching: localAlarmComponents, repeats: true)
        let identifier = "\(alarm.id.uuidString)-weekday-\(weekday)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // 로컬 시간대 정보를 클로저 외부에서 캡처
        let localHour = localComponents.hour ?? 0
        let localMinute = localComponents.minute ?? 0
        let localWeekday = localComponents.weekday ?? weekday
        let weekdayNames = ["", "일", "월", "화", "수", "목", "금", "토"]
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 반복 알람 스케줄링 실패 (요일 \(weekday)): \(error.localizedDescription)")
            } else {
                print("✅ 반복 알람 스케줄링 성공: \(alarm.name) - 매주 \(weekdayNames[weekday])요일")
                print("   - 알람 시간대: \(alarm.timezoneIdentifier) (\(alarm.countryName))")
                print("   - 알람 시간 (알람 시간대): \(alarm.hour):\(String(format: "%02d", alarm.minute))")
                print("   - 로컬 시간대에서 울릴 시간: \(localHour):\(String(format: "%02d", localMinute))")
                print("   - 로컬 시간대에서 울릴 요일: \(weekdayNames[localWeekday])요일")
            }
        }
    }
    
    // 특정 날짜 알람 스케줄링
    private func scheduleDateAlarm(alarm: Alarm, selectedDate: Date, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        // 알람 시간대에서 선택된 날짜의 알람 시간 생성
        var alarmComponents = calendar.dateComponents(in: alarmTimezone, from: selectedDate)
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        alarmComponents.timeZone = alarmTimezone
        
        guard let alarmTimeUTC = calendar.date(from: alarmComponents) else {
            print("⚠️ 날짜 알람 시간 생성 실패")
            return
        }
        
        // 로컬 시간대로 변환
        var localComponents = calendar.dateComponents(in: TimeZone.current, from: alarmTimeUTC)
        localComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: localComponents, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 날짜 알람 스케줄링 실패: \(error.localizedDescription)")
            } else {
                print("✅ 날짜 알람 스케줄링 성공: \(alarm.name)")
            }
        }
    }
    
    // 단일 알람 스케줄링 (테스트용)
    private func scheduleSingleAlarm(alarm: Alarm, alarmTimezone: TimeZone, content: UNMutableNotificationContent, calendar: Calendar, now: Date) {
        // 1. 알람 시간대에서 오늘 날짜의 알람 시간(DateComponents) 생성
        var alarmComponents = DateComponents()
        alarmComponents.year = calendar.component(.year, from: now)
        alarmComponents.month = calendar.component(.month, from: now)
        alarmComponents.day = calendar.component(.day, from: now)
        alarmComponents.hour = alarm.hour
        alarmComponents.minute = alarm.minute
        alarmComponents.second = 0
        alarmComponents.timeZone = alarmTimezone
        
        // 2. 알람 시간대의 알람 시간을 UTC Date로 변환
        guard let alarmTimeUTC = calendar.date(from: alarmComponents) else {
            print("⚠️ 알람 UTC 시간 생성 실패")
            return
        }
        
        // 3. 알람 시간이 이미 지났다면 다음 날로 설정
        let targetAlarmTimeUTC = alarmTimeUTC > now ? alarmTimeUTC : calendar.date(byAdding: .day, value: 1, to: alarmTimeUTC) ?? alarmTimeUTC
        
        // 4. UTC 기준 interval 계산
        let timeInterval = targetAlarmTimeUTC.timeIntervalSince(now)
        
        // 테스트용: 최소 5초 후에 실행되도록 설정
        let testInterval = max(5.0, timeInterval)
        
        print("🔔 단일 알람 스케줄링: \(alarm.name)")
        print("   - 알람 시간대: \(alarm.timezoneIdentifier) (\(alarm.countryName))")
        print("   - 알람 시간 (알람 시간대): \(alarm.hour):\(String(format: "%02d", alarm.minute))")
        print("   - 실행까지 남은 시간: \(Int(testInterval))초 (\(Int(testInterval / 60))분)")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: testInterval, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알람 스케줄링 실패: \(error.localizedDescription)")
            } else {
                print("✅ 알람 스케줄링 성공: \(alarm.name)")
            }
        }
    }
    
    // 알림 콘텐츠 생성
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = alarm.name
        content.body = "\(alarm.formattedTime) - \(alarm.countryFlag) \(alarm.countryName)"
        content.sound = .default
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
    
    // 알람 취소
    func cancelAlarm(_ alarm: Alarm) {
        var identifiers = [alarm.id.uuidString] // 단일 알람
        
        // 반복 알람의 경우 모든 요일별 알림 ID 추가
        for weekday in alarm.selectedWeekdays {
            identifiers.append("\(alarm.id.uuidString)-weekday-\(weekday)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("알람 취소: \(alarm.name) (ID: \(alarm.id.uuidString))")
    }
}

