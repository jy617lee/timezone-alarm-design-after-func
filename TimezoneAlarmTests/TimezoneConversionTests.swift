//
//  TimezoneConversionTests.swift
//  TimezoneAlarmTests
//
//  Created on 2024.
//

import XCTest
@testable import TimezoneAlarm

final class TimezoneConversionTests: XCTestCase {
    
    func testSeoulToLAConversion() {
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        var seoulComponents = DateComponents()
        seoulComponents.year = 2024
        seoulComponents.month = 11
        seoulComponents.day = 21
        seoulComponents.hour = 9
        seoulComponents.minute = 0
        seoulComponents.second = 0
        seoulComponents.timeZone = seoulTimezone
        
        guard let seoulTimeUTC = calendar.date(from: seoulComponents) else {
            XCTFail("서울 시간 UTC 변환 실패")
            return
        }
        
        var laComponents = calendar.dateComponents(in: laTimezone, from: seoulTimeUTC)
        laComponents.second = 0
        
        guard let laDate = calendar.date(from: laComponents) else {
            XCTFail("LA 날짜 생성 실패")
            return
        }
        
        let seoulTimeAtAlarm = calendar.dateComponents(in: seoulTimezone, from: laDate)
        
        XCTAssertEqual(seoulTimeAtAlarm.hour, 9, "서울 시간이 9시여야 합니다")
        XCTAssertEqual(seoulTimeAtAlarm.minute, 0, "서울 시간이 0분이어야 합니다")
        XCTAssertEqual(seoulTimeAtAlarm.weekday, 5, "목요일이어야 합니다")
    }
    
    func testAlarmSchedulingWithDifferentDeviceTimezone() {
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let koreaTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("한국 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        var laComponents = DateComponents()
        laComponents.year = 2025
        laComponents.month = 11
        laComponents.day = 16
        laComponents.hour = 21
        laComponents.minute = 30
        laComponents.second = 0
        laComponents.timeZone = laTimezone
        
        guard let laTime = calendar.date(from: laComponents) else {
            XCTFail("LA 시간 생성 실패")
            return
        }
        
        var koreaComponents = calendar.dateComponents(in: koreaTimezone, from: laTime)
        XCTAssertEqual(koreaComponents.year, 2025)
        XCTAssertEqual(koreaComponents.month, 11)
        XCTAssertEqual(koreaComponents.day, 17)
        XCTAssertEqual(koreaComponents.hour, 14)
        XCTAssertEqual(koreaComponents.minute, 30, "한국 시간이 14시 30분이어야 합니다")
        
        var alarmComponents = DateComponents()
        alarmComponents.year = 2025
        alarmComponents.month = 11
        alarmComponents.day = 17
        alarmComponents.hour = 14
        alarmComponents.minute = 40
        alarmComponents.second = 0
        alarmComponents.timeZone = koreaTimezone
        
        guard let alarmTimeInKorea = calendar.date(from: alarmComponents) else {
            XCTFail("알람 시간 생성 실패")
            return
        }
        
        var koreaCalendar = Calendar.current
        koreaCalendar.timeZone = koreaTimezone
        
        let koreaNowComponents = koreaCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: laTime)
        
        guard let koreaNow = koreaCalendar.date(from: koreaNowComponents) else {
            XCTFail("한국 현재 시간 생성 실패")
            return
        }
        
        var alarmTimeComponents = koreaNowComponents
        alarmTimeComponents.hour = 14
        alarmTimeComponents.minute = 40
        alarmTimeComponents.second = 0
        
        guard let todayAlarmTime = koreaCalendar.date(from: alarmTimeComponents) else {
            XCTFail("오늘 알람 시간 생성 실패")
            return
        }
        
        XCTAssertFalse(todayAlarmTime <= koreaNow, "알람 시간(14:40)은 현재 시간(14:30)보다 미래여야 합니다")
        
        var laCalendar = Calendar.current
        laCalendar.timeZone = laTimezone
        
        let laScheduledComponents = laCalendar.dateComponents(in: laTimezone, from: todayAlarmTime)
        
        XCTAssertEqual(laScheduledComponents.year, 2025)
        XCTAssertEqual(laScheduledComponents.month, 11)
        XCTAssertEqual(laScheduledComponents.day, 16, "LA 시간으로는 11월 16일이어야 합니다")
        XCTAssertEqual(laScheduledComponents.hour, 21)
        XCTAssertEqual(laScheduledComponents.minute, 40, "LA 시간으로는 21시 40분이어야 합니다")
    }
    
    func testPastTimeSelectionWithDifferentTimezone() {
        guard let koreaTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("한국 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        var koreaComponents = DateComponents()
        koreaComponents.year = 2025
        koreaComponents.month = 11
        koreaComponents.day = 17
        koreaComponents.hour = 14
        koreaComponents.minute = 30
        koreaComponents.second = 0
        koreaComponents.timeZone = koreaTimezone
        
        guard let koreaTime = calendar.date(from: koreaComponents) else {
            XCTFail("한국 시간 생성 실패")
            return
        }
        
        var laComponents = calendar.dateComponents(in: laTimezone, from: koreaTime)
        XCTAssertEqual(laComponents.year, 2025)
        XCTAssertEqual(laComponents.month, 11)
        XCTAssertEqual(laComponents.day, 16)
        XCTAssertEqual(laComponents.hour, 21)
        XCTAssertEqual(laComponents.minute, 30, "LA 시간이 21시 30분이어야 합니다")
        
        var laCalendar = Calendar.current
        laCalendar.timeZone = laTimezone
        
        var koreaDateComponents = DateComponents()
        koreaDateComponents.year = 2025
        koreaDateComponents.month = 11
        koreaDateComponents.day = 17
        koreaDateComponents.hour = 0
        koreaDateComponents.minute = 0
        koreaDateComponents.second = 0
        koreaDateComponents.timeZone = koreaTimezone
        
        guard let koreaDate = calendar.date(from: koreaDateComponents) else {
            XCTFail("한국 날짜 생성 실패")
            return
        }
        
        let laDateComponents = laCalendar.dateComponents([.year, .month, .day], from: koreaDate)
        guard let laDate = laCalendar.date(from: laDateComponents) else {
            XCTFail("LA 날짜 생성 실패")
            return
        }
        
        var laDateComponents17 = laDateComponents
        laDateComponents17.day = 17
        guard let laDate17 = laCalendar.date(from: laDateComponents17) else {
            XCTFail("LA 날짜(11월 17일) 생성 실패")
            return
        }
        
        let isPast = TimezoneConverter.isPastTime(
            alarmHour: 11,
            alarmMinute: 30,
            alarmTimezone: laTimezone,
            alarmDate: laDate17,
            now: koreaTime
        )
        
        XCTAssertFalse(isPast, "LA 시간 11월 17일 11:30은 현재 시간(한국 11월 17일 14:30)보다 미래여야 합니다")
        
        let isPast16 = TimezoneConverter.isPastTime(
            alarmHour: 11,
            alarmMinute: 30,
            alarmTimezone: laTimezone,
            alarmDate: laDate,
            now: koreaTime
        )
        
        XCTAssertTrue(isPast16, "LA 시간 11월 16일 11:30은 현재 시간(한국 11월 17일 14:30)보다 과거여야 합니다")
    }
}


