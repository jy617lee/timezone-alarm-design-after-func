//
//  TimezoneConverter.swift
//  TimezoneAlarm
//
//  공통 시간대 변환 유틸리티
//

import Foundation

/// 시간대 변환 관련 유틸리티
enum TimezoneConverter {
    
    /// 알람 시간대의 시간을 로컬 시간대 DateComponents로 변환
    /// - Parameters:
    ///   - hour: 알람 시간대의 시간 (0-23)
    ///   - minute: 알람 시간대의 분 (0-59)
    ///   - alarmTimezone: 알람이 설정된 시간대
    ///   - date: 기준 날짜 (알람 시간을 만들기 위한 날짜, 알람 시간대 기준)
    /// - Returns: 로컬 시간대 DateComponents (nil이면 변환 실패)
    static func convertToLocalComponents(
        hour: Int,
        minute: Int,
        alarmTimezone: TimeZone,
        date: Date
    ) -> DateComponents? {
        // 알람 시간대의 Calendar 생성
        var alarmCalendar = Calendar.current
        alarmCalendar.timeZone = alarmTimezone
        
        // 알람 시간대에서 DateComponents 생성
        var alarmComponents = alarmCalendar.dateComponents([.year, .month, .day], from: date)
        alarmComponents.hour = hour
        alarmComponents.minute = minute
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
    
    /// 알람 시간대의 시간이 현재 시간보다 과거인지 검증 (UTC 기준 비교)
    /// - Parameters:
    ///   - alarmHour: 알람 시간대의 시간 (0-23)
    ///   - alarmMinute: 알람 시간대의 분 (0-59)
    ///   - alarmTimezone: 알람이 설정된 시간대
    ///   - alarmDate: 기준 날짜 (알람 시간을 만들기 위한 날짜, 알람 시간대 기준)
    ///   - now: 현재 시간 (기본값: Date(), UTC 기준)
    /// - Returns: 과거 시간이면 true, 미래 시간이면 false
    static func isPastTime(
        alarmHour: Int,
        alarmMinute: Int,
        alarmTimezone: TimeZone,
        alarmDate: Date,
        now: Date = Date()
    ) -> Bool {
        // 알람 시간대의 Calendar 생성
        var alarmCalendar = Calendar.current
        alarmCalendar.timeZone = alarmTimezone
        
        // alarmDate를 알람 시간대 기준으로 해석하여 날짜 추출
        let alarmDateComponents = alarmCalendar.dateComponents([.year, .month, .day], from: alarmDate)
        
        // 알람 시간 설정 (alarmDate의 날짜에 alarmHour, alarmMinute 설정)
        var alarmComponents = alarmDateComponents
        alarmComponents.hour = alarmHour
        alarmComponents.minute = alarmMinute
        alarmComponents.second = 0
        
        // 알람 시간을 UTC Date로 변환
        guard let alarmTimeUTC = alarmCalendar.date(from: alarmComponents) else {
            return true // 변환 실패 시 과거로 간주
        }
        
        // 현재 시간은 이미 UTC 기준이므로 직접 비교
        return alarmTimeUTC <= now
    }
}

