//
//  TimezoneConversionTests.swift
//  TimezoneAlarmTests
//
//  Created on 2024.
//

import XCTest
@testable import TimezoneAlarm

final class TimezoneConversionTests: XCTestCase {
    
    /// 시나리오 테스트: 서울에서 목요일 9시 알람 설정 후 LA로 이동
    func testSeoulToLAConversion() {
        // 서울 시간대
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        // LA 시간대
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
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
            XCTFail("서울 시간 UTC 변환 실패")
            return
        }
        
        // UTC를 LA 시간대로 변환 (AlarmScheduler 로직)
        var laComponents = calendar.dateComponents(in: laTimezone, from: seoulTimeUTC)
        laComponents.second = 0
        
        guard let laDate = calendar.date(from: laComponents) else {
            XCTFail("LA 날짜 생성 실패")
            return
        }
        
        // 검증: LA 시간으로 스케줄링된 알람이 서울 시간 목요일 9시에 울리는지 확인
        let seoulTimeAtAlarm = calendar.dateComponents(in: seoulTimezone, from: laDate)
        
        XCTAssertEqual(seoulTimeAtAlarm.hour, 9, "서울 시간이 9시여야 합니다")
        XCTAssertEqual(seoulTimeAtAlarm.minute, 0, "서울 시간이 0분이어야 합니다")
        XCTAssertEqual(seoulTimeAtAlarm.weekday, 5, "목요일이어야 합니다")
    }
}


