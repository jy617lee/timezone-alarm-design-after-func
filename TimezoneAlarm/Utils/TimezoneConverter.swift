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
    
    /// 알람 시간대의 시간이 현재 시간보다 과거인지 검증
    /// - Parameters:
    ///   - hour: 알람 시간대의 시간 (0-23)
    ///   - minute: 알람 시간대의 분 (0-59)
    ///   - alarmTimezone: 알람이 설정된 시간대
    ///   - date: 기준 날짜 (알람 시간을 만들기 위한 날짜, 알람 시간대 기준)
    ///   - now: 현재 시간 (기본값: Date())
    /// - Returns: 과거 시간이면 true, 미래 시간이면 false
    static func isPastTime(
        hour: Int,
        minute: Int,
        alarmTimezone: TimeZone,
        date: Date,
        now: Date = Date()
    ) -> Bool {
        // 알람 시간대의 Calendar 생성
        var alarmCalendar = Calendar.current
        alarmCalendar.timeZone = alarmTimezone
        
        // 알람 시간대에서 현재 날짜/시간 가져오기
        let alarmTimezoneNowComponents = alarmCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        
        // 알람 시간대의 현재 시간을 UTC Date로 변환 (비교용)
        guard let alarmTimezoneNow = alarmCalendar.date(from: alarmTimezoneNowComponents) else {
            return true // 변환 실패 시 과거로 간주
        }
        
        // date를 알람 시간대 기준으로 해석하여 날짜 추출
        let alarmDateComponents = alarmCalendar.dateComponents([.year, .month, .day], from: date)
        
        // 알람 시간 설정 (date의 날짜에 hour, minute 설정)
        var alarmComponents = alarmDateComponents
        alarmComponents.hour = hour
        alarmComponents.minute = minute
        alarmComponents.second = 0
        
        guard let alarmTime = alarmCalendar.date(from: alarmComponents) else {
            return true // 변환 실패 시 과거로 간주
        }
        
        // 알람 시간이 현재 시간보다 과거인지 확인
        return alarmTime <= alarmTimezoneNow
    }
    
    /// 알람 시간대의 시간을 로컬 시간대 Date로 변환
    /// - Parameters:
    ///   - hour: 알람 시간대의 시간 (0-23)
    ///   - minute: 알람 시간대의 분 (0-59)
    ///   - alarmTimezone: 알람이 설정된 시간대
    ///   - date: 기준 날짜 (알람 시간을 만들기 위한 날짜, 알람 시간대 기준)
    /// - Returns: 로컬 시간대 Date (nil이면 변환 실패)
    static func convertToLocalDate(
        hour: Int,
        minute: Int,
        alarmTimezone: TimeZone,
        date: Date
    ) -> Date? {
        guard let localComponents = convertToLocalComponents(
            hour: hour,
            minute: minute,
            alarmTimezone: alarmTimezone,
            date: date
        ) else {
            return nil
        }
        
        return Calendar.current.date(from: localComponents)
    }
}

