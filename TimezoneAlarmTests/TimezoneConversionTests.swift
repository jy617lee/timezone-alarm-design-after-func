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
    
    func testConvertToUTCDate() {
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 한국 시간대: 2024년 11월 21일 9시 0분
        var seoulDateComponents = DateComponents()
        seoulDateComponents.year = 2024
        seoulDateComponents.month = 11
        seoulDateComponents.day = 21
        seoulDateComponents.hour = 0
        seoulDateComponents.minute = 0
        seoulDateComponents.second = 0
        seoulDateComponents.timeZone = seoulTimezone
        
        guard let seoulDate = calendar.date(from: seoulDateComponents) else {
            XCTFail("서울 날짜 생성 실패")
            return
        }
        
        // 한국 시간대 9시 0분을 UTC로 변환
        guard let utcDate = TimezoneConverter.convertToUTCDate(
            alarmHour: 9,
            alarmMinute: 0,
            alarmTimezone: seoulTimezone,
            alarmDate: seoulDate
        ) else {
            XCTFail("UTC 변환 실패")
            return
        }
        
        // UTC Date를 한국 시간대로 다시 변환하여 검증
        let seoulComponents = calendar.dateComponents(in: seoulTimezone, from: utcDate)
        XCTAssertEqual(seoulComponents.year, 2024)
        XCTAssertEqual(seoulComponents.month, 11)
        XCTAssertEqual(seoulComponents.day, 21)
        XCTAssertEqual(seoulComponents.hour, 9)
        XCTAssertEqual(seoulComponents.minute, 0)
    }
    
    func testConvertToUTCDateWithLATimezone() {
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // LA 시간대: 2024년 11월 21일 자정
        var laDateComponents = DateComponents()
        laDateComponents.year = 2024
        laDateComponents.month = 11
        laDateComponents.day = 21
        laDateComponents.hour = 0
        laDateComponents.minute = 0
        laDateComponents.second = 0
        laDateComponents.timeZone = laTimezone
        
        guard let laDate = calendar.date(from: laDateComponents) else {
            XCTFail("LA 날짜 생성 실패")
            return
        }
        
        // LA 시간대 14시 0분을 UTC로 변환
        guard let utcDate = TimezoneConverter.convertToUTCDate(
            alarmHour: 14,
            alarmMinute: 0,
            alarmTimezone: laTimezone,
            alarmDate: laDate
        ) else {
            XCTFail("UTC 변환 실패")
            return
        }
        
        // UTC Date를 LA 시간대로 다시 변환하여 검증
        let laComponents = calendar.dateComponents(in: laTimezone, from: utcDate)
        XCTAssertEqual(laComponents.year, 2024)
        XCTAssertEqual(laComponents.month, 11)
        XCTAssertEqual(laComponents.day, 21)
        XCTAssertEqual(laComponents.hour, 14)
        XCTAssertEqual(laComponents.minute, 0)
    }
    
    func testConvertToUTCDateWithMidnightBoundary() {
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 한국 시간대: 2024년 11월 21일 자정
        var seoulDateComponents = DateComponents()
        seoulDateComponents.year = 2024
        seoulDateComponents.month = 11
        seoulDateComponents.day = 21
        seoulDateComponents.hour = 0
        seoulDateComponents.minute = 0
        seoulDateComponents.second = 0
        seoulDateComponents.timeZone = seoulTimezone
        
        guard let seoulDate = calendar.date(from: seoulDateComponents) else {
            XCTFail("서울 날짜 생성 실패")
            return
        }
        
        // 자정 (0시 0분) 변환
        guard let utcDateMidnight = TimezoneConverter.convertToUTCDate(
            alarmHour: 0,
            alarmMinute: 0,
            alarmTimezone: seoulTimezone,
            alarmDate: seoulDate
        ) else {
            XCTFail("자정 UTC 변환 실패")
            return
        }
        
        // 23시 59분 변환
        guard let utcDate2359 = TimezoneConverter.convertToUTCDate(
            alarmHour: 23,
            alarmMinute: 59,
            alarmTimezone: seoulTimezone,
            alarmDate: seoulDate
        ) else {
            XCTFail("23시 59분 UTC 변환 실패")
            return
        }
        
        // 자정이 23시 59분보다 이전이어야 함
        XCTAssertLessThan(utcDateMidnight, utcDate2359, "자정은 23시 59분보다 이전이어야 합니다")
        
        // 검증: 자정 변환 결과
        let seoulComponentsMidnight = calendar.dateComponents(in: seoulTimezone, from: utcDateMidnight)
        XCTAssertEqual(seoulComponentsMidnight.hour, 0)
        XCTAssertEqual(seoulComponentsMidnight.minute, 0)
        
        // 검증: 23시 59분 변환 결과
        let seoulComponents2359 = calendar.dateComponents(in: seoulTimezone, from: utcDate2359)
        XCTAssertEqual(seoulComponents2359.hour, 23)
        XCTAssertEqual(seoulComponents2359.minute, 59)
    }
    
    func testConvertToUTCDateWithDifferentDates() {
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 2024년 11월 21일
        var date1Components = DateComponents()
        date1Components.year = 2024
        date1Components.month = 11
        date1Components.day = 21
        date1Components.hour = 0
        date1Components.minute = 0
        date1Components.second = 0
        date1Components.timeZone = seoulTimezone
        
        guard let date1 = calendar.date(from: date1Components) else {
            XCTFail("날짜1 생성 실패")
            return
        }
        
        // 2024년 11월 22일
        var date2Components = DateComponents()
        date2Components.year = 2024
        date2Components.month = 11
        date2Components.day = 22
        date2Components.hour = 0
        date2Components.minute = 0
        date2Components.second = 0
        date2Components.timeZone = seoulTimezone
        
        guard let date2 = calendar.date(from: date2Components) else {
            XCTFail("날짜2 생성 실패")
            return
        }
        
        // 같은 시간(9시 0분)이지만 다른 날짜
        guard let utcDate1 = TimezoneConverter.convertToUTCDate(
            alarmHour: 9,
            alarmMinute: 0,
            alarmTimezone: seoulTimezone,
            alarmDate: date1
        ) else {
            XCTFail("UTC 변환1 실패")
            return
        }
        
        guard let utcDate2 = TimezoneConverter.convertToUTCDate(
            alarmHour: 9,
            alarmMinute: 0,
            alarmTimezone: seoulTimezone,
            alarmDate: date2
        ) else {
            XCTFail("UTC 변환2 실패")
            return
        }
        
        // date2가 date1보다 하루 뒤여야 함
        let timeDifference = utcDate2.timeIntervalSince(utcDate1)
        XCTAssertEqual(timeDifference, 24 * 60 * 60, accuracy: 60, "하루 차이(24시간)가 있어야 합니다")
    }
    
    func testInterpretDateInAlarmTimezone() {
        guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("서울 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 로컬 시간대: 2024년 11월 21일 15시 (한국 시간 기준)
        var localComponents = DateComponents()
        localComponents.year = 2024
        localComponents.month = 11
        localComponents.day = 21
        localComponents.hour = 15
        localComponents.minute = 0
        localComponents.second = 0
        localComponents.timeZone = seoulTimezone
        
        guard let localDate = calendar.date(from: localComponents) else {
            XCTFail("로컬 날짜 생성 실패")
            return
        }
        
        // 한국 시간대 기준으로 해석
        guard let seoulDate = TimezoneConverter.interpretDateInAlarmTimezone(
            date: localDate,
            alarmTimezone: seoulTimezone
        ) else {
            XCTFail("한국 시간대 해석 실패")
            return
        }
        
        let seoulComponents = calendar.dateComponents(in: seoulTimezone, from: seoulDate)
        XCTAssertEqual(seoulComponents.year, 2024)
        XCTAssertEqual(seoulComponents.month, 11)
        XCTAssertEqual(seoulComponents.day, 21)
        XCTAssertEqual(seoulComponents.hour, 0, "날짜만 추출하므로 시간은 0시여야 합니다")
        XCTAssertEqual(seoulComponents.minute, 0)
        
        // LA 시간대 기준으로 해석 (한국 11월 21일 15시는 LA 11월 20일 23시)
        guard let laDate = TimezoneConverter.interpretDateInAlarmTimezone(
            date: localDate,
            alarmTimezone: laTimezone
        ) else {
            XCTFail("LA 시간대 해석 실패")
            return
        }
        
        let laComponents = calendar.dateComponents(in: laTimezone, from: laDate)
        XCTAssertEqual(laComponents.year, 2024)
        XCTAssertEqual(laComponents.month, 11)
        XCTAssertEqual(laComponents.day, 20, "한국 11월 21일 15시는 LA 시간대로는 11월 20일입니다")
        XCTAssertEqual(laComponents.hour, 0, "날짜만 추출하므로 시간은 0시여야 합니다")
        XCTAssertEqual(laComponents.minute, 0)
    }
    
    // MARK: - 날짜 경계 케이스 테스트
    
    /// findNextAlarmDate 로직 테스트: LA 기기에서 한국 시간 알람 설정 (날짜 경계 케이스)
    func testFindNextAlarmDateWithDateBoundary() {
        guard let koreaTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("한국 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 시나리오: LA 시간 11월 18일 16:00 (UTC: 11월 19일 00:00)
        // 한국 시간: 11월 19일 09:00
        // 한국 알람 시간: 09:00 (이미 지남)
        // → 다음 날(11월 20일 09:00)로 설정되어야 함
        
        var laComponents = DateComponents()
        laComponents.year = 2025
        laComponents.month = 11
        laComponents.day = 18
        laComponents.hour = 16
        laComponents.minute = 0
        laComponents.second = 0
        laComponents.timeZone = laTimezone
        
        guard let laTime = calendar.date(from: laComponents) else {
            XCTFail("LA 시간 생성 실패")
            return
        }
        
        // 한국 시간대에서 현재 시간 확인
        var koreaCalendar = Calendar.current
        koreaCalendar.timeZone = koreaTimezone
        let koreaComponents = koreaCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: laTime)
        
        // 한국 시간이 11월 19일 09:00인지 확인
        XCTAssertEqual(koreaComponents.year, 2025)
        XCTAssertEqual(koreaComponents.month, 11)
        XCTAssertEqual(koreaComponents.day, 19)
        XCTAssertEqual(koreaComponents.hour, 9)
        
        // 한국 알람 시간 09:00 (이미 지남)
        // 오늘 알람 시간 생성
        guard let todayAlarmTime = TimezoneConverter.convertToUTCDate(
            alarmHour: 9,
            alarmMinute: 0,
            alarmTimezone: koreaTimezone,
            alarmDate: koreaCalendar.date(from: koreaComponents)!
        ) else {
            XCTFail("오늘 알람 시간 생성 실패")
            return
        }
        
        // 오늘 알람 시간이 현재 시간보다 과거인지 확인
        XCTAssertTrue(todayAlarmTime <= laTime, "오늘 알람 시간(09:00)은 현재 시간(09:00)보다 과거이거나 같아야 합니다")
        
        // 다음 날 알람 시간 계산 (버그 수정 후)
        // UTC Date에 직접 24시간을 더함
        let nextDayUTC = todayAlarmTime.addingTimeInterval(24 * 60 * 60)
        
        // 다음 날을 알람 시간대 기준으로 해석
        guard let nextDayInAlarmTimezone = TimezoneConverter.interpretDateInAlarmTimezone(
            date: nextDayUTC,
            alarmTimezone: koreaTimezone
        ) else {
            XCTFail("다음 날 해석 실패")
            return
        }
        
        // 다음 날 알람 시간 생성
        guard let nextAlarmTime = TimezoneConverter.convertToUTCDate(
            alarmHour: 9,
            alarmMinute: 0,
            alarmTimezone: koreaTimezone,
            alarmDate: nextDayInAlarmTimezone
        ) else {
            XCTFail("다음 날 알람 시간 생성 실패")
            return
        }
        
        // 다음 날 알람 시간이 한국 시간 11월 20일 09:00인지 확인
        let nextAlarmComponents = koreaCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextAlarmTime)
        XCTAssertEqual(nextAlarmComponents.year, 2025)
        XCTAssertEqual(nextAlarmComponents.month, 11)
        XCTAssertEqual(nextAlarmComponents.day, 20, "다음 날 알람은 11월 20일이어야 합니다")
        XCTAssertEqual(nextAlarmComponents.hour, 9)
        XCTAssertEqual(nextAlarmComponents.minute, 0)
        
        // 다음 날 알람 시간이 현재 시간보다 미래인지 확인
        XCTAssertTrue(nextAlarmTime > laTime, "다음 날 알람 시간은 현재 시간보다 미래여야 합니다")
        
        // 시간 차이가 약 24시간인지 확인
        let timeDifference = nextAlarmTime.timeIntervalSince(todayAlarmTime)
        XCTAssertEqual(timeDifference, 24 * 60 * 60, accuracy: 60, "하루 차이(24시간)가 있어야 합니다")
    }
    
    /// findNextAlarmDate 로직 테스트: 한국 기기에서 LA 시간 알람 설정 (날짜 경계 케이스)
    func testFindNextAlarmDateWithDateBoundaryReverse() {
        guard let koreaTimezone = TimeZone(identifier: "Asia/Seoul") else {
            XCTFail("한국 시간대를 찾을 수 없습니다")
            return
        }
        
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        let calendar = Calendar.current
        
        // 시나리오: 한국 시간 11월 19일 09:00 (UTC: 11월 19일 00:00)
        // LA 시간: 11월 18일 16:00
        // LA 알람 시간: 16:00 (이미 지남)
        // → 다음 날(11월 19일 16:00)로 설정되어야 함
        
        var koreaComponents = DateComponents()
        koreaComponents.year = 2025
        koreaComponents.month = 11
        koreaComponents.day = 19
        koreaComponents.hour = 9
        koreaComponents.minute = 0
        koreaComponents.second = 0
        koreaComponents.timeZone = koreaTimezone
        
        guard let koreaTime = calendar.date(from: koreaComponents) else {
            XCTFail("한국 시간 생성 실패")
            return
        }
        
        // LA 시간대에서 현재 시간 확인
        var laCalendar = Calendar.current
        laCalendar.timeZone = laTimezone
        let laComponents = laCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: koreaTime)
        
        // LA 시간이 11월 18일 16:00인지 확인
        XCTAssertEqual(laComponents.year, 2025)
        XCTAssertEqual(laComponents.month, 11)
        XCTAssertEqual(laComponents.day, 18)
        XCTAssertEqual(laComponents.hour, 16)
        
        // LA 알람 시간 16:00 (이미 지남)
        // 오늘 알람 시간 생성
        guard let todayAlarmTime = TimezoneConverter.convertToUTCDate(
            alarmHour: 16,
            alarmMinute: 0,
            alarmTimezone: laTimezone,
            alarmDate: laCalendar.date(from: laComponents)!
        ) else {
            XCTFail("오늘 알람 시간 생성 실패")
            return
        }
        
        // 오늘 알람 시간이 현재 시간보다 과거인지 확인
        XCTAssertTrue(todayAlarmTime <= koreaTime, "오늘 알람 시간(16:00)은 현재 시간(16:00)보다 과거이거나 같아야 합니다")
        
        // 다음 날 알람 시간 계산 (버그 수정 후)
        // UTC Date에 직접 24시간을 더함
        let nextDayUTC = todayAlarmTime.addingTimeInterval(24 * 60 * 60)
        
        // 다음 날을 알람 시간대 기준으로 해석
        guard let nextDayInAlarmTimezone = TimezoneConverter.interpretDateInAlarmTimezone(
            date: nextDayUTC,
            alarmTimezone: laTimezone
        ) else {
            XCTFail("다음 날 해석 실패")
            return
        }
        
        // 다음 날 알람 시간 생성
        guard let nextAlarmTime = TimezoneConverter.convertToUTCDate(
            alarmHour: 16,
            alarmMinute: 0,
            alarmTimezone: laTimezone,
            alarmDate: nextDayInAlarmTimezone
        ) else {
            XCTFail("다음 날 알람 시간 생성 실패")
            return
        }
        
        // 다음 날 알람 시간이 LA 시간 11월 19일 16:00인지 확인
        let nextAlarmComponents = laCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextAlarmTime)
        XCTAssertEqual(nextAlarmComponents.year, 2025)
        XCTAssertEqual(nextAlarmComponents.month, 11)
        XCTAssertEqual(nextAlarmComponents.day, 19, "다음 날 알람은 11월 19일이어야 합니다")
        XCTAssertEqual(nextAlarmComponents.hour, 16)
        XCTAssertEqual(nextAlarmComponents.minute, 0)
        
        // 다음 날 알람 시간이 현재 시간보다 미래인지 확인
        XCTAssertTrue(nextAlarmTime > koreaTime, "다음 날 알람 시간은 현재 시간보다 미래여야 합니다")
    }
}


