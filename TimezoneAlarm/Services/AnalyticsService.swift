//
//  AnalyticsService.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation
// TODO: Firebase SDK 추가 후 주석 해제
// import FirebaseAnalytics

class AnalyticsService {
    nonisolated(unsafe) static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - 알람 이벤트
    
    /// 알람 등록 이벤트
    func logAlarmCreated(alarm: Alarm) {
        let parameters: [String: Any] = [
            "alarm_id": alarm.id.uuidString,
            "alarm_name": alarm.name,
            "alarm_hour": alarm.hour,
            "alarm_minute": alarm.minute,
            "timezone_identifier": alarm.timezoneIdentifier,
            "country_name": alarm.countryName,
            "country_flag": alarm.countryFlag,
            "is_enabled": alarm.isEnabled,
            "has_weekdays": !alarm.selectedWeekdays.isEmpty,
            "has_date": alarm.selectedDate != nil,
            "device_language": Locale.current.language.languageCode?.identifier ?? "unknown",
            "device_timezone": TimeZone.current.identifier
        ]
        
        // TODO: Firebase SDK 추가 후 주석 해제
        // Analytics.logEvent("alarm_created", parameters: parameters)
        debugLog("📊 Analytics: alarm_created - \(alarm.name)")
    }
    
    /// 알람 수정 이벤트
    func logAlarmUpdated(alarm: Alarm) {
        let parameters: [String: Any] = [
            "alarm_id": alarm.id.uuidString,
            "alarm_name": alarm.name,
            "alarm_hour": alarm.hour,
            "alarm_minute": alarm.minute,
            "timezone_identifier": alarm.timezoneIdentifier,
            "country_name": alarm.countryName,
            "country_flag": alarm.countryFlag,
            "is_enabled": alarm.isEnabled,
            "has_weekdays": !alarm.selectedWeekdays.isEmpty,
            "has_date": alarm.selectedDate != nil,
            "device_language": Locale.current.language.languageCode?.identifier ?? "unknown",
            "device_timezone": TimeZone.current.identifier
        ]
        
        // TODO: Firebase SDK 추가 후 주석 해제
        // Analytics.logEvent("alarm_updated", parameters: parameters)
        debugLog("📊 Analytics: alarm_updated - \(alarm.name)")
    }
    
    /// 알람 삭제 이벤트
    func logAlarmDeleted(alarm: Alarm) {
        let parameters: [String: Any] = [
            "alarm_id": alarm.id.uuidString,
            "alarm_name": alarm.name,
            "alarm_hour": alarm.hour,
            "alarm_minute": alarm.minute,
            "timezone_identifier": alarm.timezoneIdentifier,
            "country_name": alarm.countryName,
            "country_flag": alarm.countryFlag,
            "device_language": Locale.current.language.languageCode?.identifier ?? "unknown",
            "device_timezone": TimeZone.current.identifier
        ]
        
        // TODO: Firebase SDK 추가 후 주석 해제
        // Analytics.logEvent("alarm_deleted", parameters: parameters)
        debugLog("📊 Analytics: alarm_deleted - \(alarm.name)")
    }
    
    /// 알람 비활성화/활성화 이벤트
    func logAlarmToggled(alarm: Alarm, isEnabled: Bool) {
        let parameters: [String: Any] = [
            "alarm_id": alarm.id.uuidString,
            "alarm_name": alarm.name,
            "is_enabled": isEnabled,
            "device_language": Locale.current.language.languageCode?.identifier ?? "unknown",
            "device_timezone": TimeZone.current.identifier
        ]
        
        let eventName = isEnabled ? "alarm_enabled" : "alarm_disabled"
        // TODO: Firebase SDK 추가 후 주석 해제
        // Analytics.logEvent(eventName, parameters: parameters)
        debugLog("📊 Analytics: \(eventName) - \(alarm.name)")
    }
    
    /// 알람 dismiss 이벤트
    func logAlarmDismissed(alarm: Alarm) {
        let parameters: [String: Any] = [
            "alarm_id": alarm.id.uuidString,
            "alarm_name": alarm.name,
            "alarm_hour": alarm.hour,
            "alarm_minute": alarm.minute,
            "timezone_identifier": alarm.timezoneIdentifier,
            "country_name": alarm.countryName,
            "country_flag": alarm.countryFlag,
            "device_language": Locale.current.language.languageCode?.identifier ?? "unknown",
            "device_timezone": TimeZone.current.identifier
        ]
        
        // TODO: Firebase SDK 추가 후 주석 해제
        // Analytics.logEvent("alarm_dismissed", parameters: parameters)
        debugLog("📊 Analytics: alarm_dismissed - \(alarm.name)")
    }
}

