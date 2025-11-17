//
//  TimezoneConversionTest.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation

/// 타임존 변환 로직 검증을 위한 테스트 유틸리티
struct TimezoneConversionTest {
    
    /// 시나리오 테스트: 서울에서 목요일 9시 알람 설정 후 LA로 이동
    static func testSeoulToLA() {
        debugLog("🧪 시나리오 테스트: 서울 → LA")
        debugLog("=" * 50)
        
        // 서울 시간대
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            debugLog("❌ 서울 시간대를 찾을 수 없습니다")
            return
        }
        
        // LA 시간대
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            debugLog("❌ LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 시나리오: 서울에서 매주 목요일 오전 9시 알람 설정
        // alarmTimezone = Asia/Seoul, hour = 9, minute = 0, weekday = 5 (목요일)
        
        debugLog("\n📋 시나리오:")
        debugLog("   1. 서울에서 매주 목요일 오전 9시 알람 설정")
        debugLog("   2. LA로 이동")
        debugLog("   3. 한국 시간 목요일 오전 9시에 알람이 울려야 함")
        
        // AlarmScheduler의 convertAlarmTimeToLocalComponents 로직 테스트
        debugLog("\n🔍 AlarmScheduler 변환 로직 테스트:")
        
        // 현재 시간을 기준으로 다음 목요일 찾기
        var targetDate = now
        let todayComponents = calendar.dateComponents(in: seoulTimezone, from: now)
        if todayComponents.weekday == 5 {
            // 오늘이 목요일이면 오늘 사용
            targetDate = now
        } else {
            // 다음 주 목요일로
            targetDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        }
        
        // 서울 시간대에서 목요일 9시를 UTC로 변환
        var seoulComponents = calendar.dateComponents(in: seoulTimezone, from: targetDate)
        seoulComponents.hour = 9
        seoulComponents.minute = 0
        seoulComponents.second = 0
        seoulComponents.weekday = 5 // 목요일
        seoulComponents.timeZone = seoulTimezone
        
        guard let seoulTimeUTC = calendar.date(from: seoulComponents) else {
            debugLog("❌ 서울 시간 UTC 변환 실패")
            return
        }
        
        debugLog("   📍 서울 시간 목요일 9:00")
        debugLog("      - 서울 시간: \(formatDate(seoulTimeUTC, timezone: seoulTimezone))")
        debugLog("      - UTC: \(formatDate(seoulTimeUTC, timezone: TimeZone(identifier: "UTC")!))")
        
        // UTC를 LA 시간대로 변환 (AlarmScheduler 로직)
        var laComponents = calendar.dateComponents(in: laTimezone, from: seoulTimeUTC)
        laComponents.second = 0
        
        debugLog("   📍 LA 시간으로 변환된 알람 스케줄:")
        debugLog("      - LA 시간: \(laComponents.year ?? 0)-\(String(format: "%02d", laComponents.month ?? 0))-\(String(format: "%02d", laComponents.day ?? 0)) \(String(format: "%02d", laComponents.hour ?? 0)):\(String(format: "%02d", laComponents.minute ?? 0))")
        debugLog("      - 요일: \(laComponents.weekday ?? 0) (목요일=5)")
        
        if let laDate = calendar.date(from: laComponents) {
            debugLog("      - LA 시간 표시: \(formatDate(laDate, timezone: laTimezone))")
            debugLog("      - UTC: \(formatDate(laDate, timezone: TimeZone(identifier: "UTC")!))")
            
            // 검증: LA 시간으로 스케줄링된 알람이 서울 시간 목요일 9시에 울리는지 확인
            let seoulTimeAtAlarm = calendar.dateComponents(in: seoulTimezone, from: laDate)
            let isCorrect = seoulTimeAtAlarm.hour == 9 && seoulTimeAtAlarm.minute == 0 && seoulTimeAtAlarm.weekday == 5
            
            debugLog("\n✅ 검증 결과:")
            if isCorrect {
                debugLog("   ✅ 성공: LA 시간으로 스케줄링된 알람이")
                debugLog("      서울 시간 목요일 오전 9시에 정확히 울립니다!")
            } else {
                debugLog("   ❌ 실패: 서울 시간 \(seoulTimeAtAlarm.hour ?? 0):\(String(format: "%02d", seoulTimeAtAlarm.minute ?? 0)), 요일: \(seoulTimeAtAlarm.weekday ?? 0)")
            }
        } else {
            debugLog("   ❌ LA 날짜 생성 실패")
        }
        
        debugLog("=" * 50)
    }
    
    private static func formatDate(_ date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

// String extension for repeating
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

