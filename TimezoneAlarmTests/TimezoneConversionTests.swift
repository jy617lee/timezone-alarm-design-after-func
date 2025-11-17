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
        
        // 고정된 날짜 사용: 2024년 11월 21일 (목요일)
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
    
    /// 이슈 #35: 기기 시간대와 알람 시간대가 다를 때 스케줄링 오류
    /// 시나리오: 기기 시간이 LA 시간으로 설정되어 있고, 한국 시간으로 알람 생성
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
        
        // 시나리오: LA 시간 2025년 11월 16일 21시 30분 = 한국 시간 2025년 11월 17일 14시 30분
        // 기기 시간대는 LA, 알람은 한국 시간으로 14시 40분에 설정
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
        
        // 한국 시간으로 변환하여 확인 (14시 30분이어야 함)
        var koreaComponents = calendar.dateComponents(in: koreaTimezone, from: laTime)
        XCTAssertEqual(koreaComponents.year, 2025)
        XCTAssertEqual(koreaComponents.month, 11)
        XCTAssertEqual(koreaComponents.day, 17)
        XCTAssertEqual(koreaComponents.hour, 14)
        XCTAssertEqual(koreaComponents.minute, 30, "한국 시간이 14시 30분이어야 합니다")
        
        // 알람: 한국 시간으로 2025년 11월 17일 14시 40분
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
        
        // AlarmScheduler의 findNextAlarmDate 로직 시뮬레이션
        // 기기 시간대(LA)에서 현재 시간은 laTime
        // 알람 시간대(한국)에서 현재 시간을 계산
        var koreaCalendar = Calendar.current
        koreaCalendar.timeZone = koreaTimezone
        
        // 알람 시간대에서 현재 날짜/시간 가져오기
        let koreaNowComponents = koreaCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: laTime)
        
        // 알람 시간대의 현재 시간을 UTC Date로 변환
        guard let koreaNow = koreaCalendar.date(from: koreaNowComponents) else {
            XCTFail("한국 현재 시간 생성 실패")
            return
        }
        
        // 알람 시간 설정
        var alarmTimeComponents = koreaNowComponents
        alarmTimeComponents.hour = 14
        alarmTimeComponents.minute = 40
        alarmTimeComponents.second = 0
        
        guard let todayAlarmTime = koreaCalendar.date(from: alarmTimeComponents) else {
            XCTFail("오늘 알람 시간 생성 실패")
            return
        }
        
        // 알람 시간이 이미 지났는지 확인
        // 한국 시간 14:40 > 한국 시간 14:30이므로 아직 지나지 않음
        XCTAssertFalse(todayAlarmTime <= koreaNow, "알람 시간(14:40)은 현재 시간(14:30)보다 미래여야 합니다")
        
        // 로컬 시간대(LA)로 변환하여 스케줄링 시간 확인
        var laCalendar = Calendar.current
        laCalendar.timeZone = laTimezone
        
        let laScheduledComponents = laCalendar.dateComponents(in: laTimezone, from: todayAlarmTime)
        
        // LA 시간으로는 21시 40분이어야 함 (한국 14:40 = LA 21:40, 같은 날)
        XCTAssertEqual(laScheduledComponents.year, 2025)
        XCTAssertEqual(laScheduledComponents.month, 11)
        XCTAssertEqual(laScheduledComponents.day, 16, "LA 시간으로는 11월 16일이어야 합니다")
        XCTAssertEqual(laScheduledComponents.hour, 21)
        XCTAssertEqual(laScheduledComponents.minute, 40, "LA 시간으로는 21시 40분이어야 합니다")
    }
    
    /// 이슈 #34: Past Time Selection 오류
    /// 시나리오: 기기 시간이 한국 시간으로 설정되어 있고, LA 기준으로 알람 생성 시도
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
        
        // 시나리오: 한국 시간 2025년 11월 17일 14시 30분 = LA 시간 2025년 11월 16일 21시 30분
        // 기기 시간대는 한국, 알람은 LA 시간으로 11시 30분에 설정
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
        
        // LA 시간으로 변환하여 확인 (21시 30분이어야 함)
        var laComponents = calendar.dateComponents(in: laTimezone, from: koreaTime)
        XCTAssertEqual(laComponents.year, 2025)
        XCTAssertEqual(laComponents.month, 11)
        XCTAssertEqual(laComponents.day, 16)
        XCTAssertEqual(laComponents.hour, 21)
        XCTAssertEqual(laComponents.minute, 30, "LA 시간이 21시 30분이어야 합니다")
        
        // 알람: LA 시간으로 2025년 11월 17일 11시 30분 (한국 시간 14시 30분과 동일)
        // 이는 한국 시간 14시 30분보다 이전이 아니므로 정상적으로 생성되어야 함
        
        // AlarmFormView의 검증 로직 시뮬레이션
        // datePickerValue는 로컬 시간대(한국) 기준 11월 17일
        // 알람 시간대(LA)에서 해석하면 11월 16일 또는 11월 17일 (시간에 따라)
        var laCalendar = Calendar.current
        laCalendar.timeZone = laTimezone
        
        // 시나리오: 사용자가 한국 시간 11월 17일을 선택
        // 이는 LA 시간으로는 11월 16일 21:30 이후이므로 11월 17일로 해석됨
        // 하지만 datePickerValue는 한국 시간 11월 17일 00:00이므로, LA 시간으로는 11월 16일 07:00
        
        // 한국 시간 11월 17일 00:00을 LA 시간으로 변환
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
        
        // 로컬 시간대(한국)의 날짜를 알람 시간대(LA)에서 해석
        // datePickerValue는 한국 시간 11월 17일 00:00
        // LA 시간으로는 11월 16일 07:00이므로, LA 날짜는 11월 16일
        let laDateComponents = laCalendar.dateComponents([.year, .month, .day], from: koreaDate)
        guard let laDate = laCalendar.date(from: laDateComponents) else {
            XCTFail("LA 날짜 생성 실패")
            return
        }
        
        // 하지만 사용자가 선택한 날짜는 11월 17일이므로, LA 시간으로 11월 17일 11:30을 검증해야 함
        // 따라서 11월 17일 날짜를 사용
        var laDateComponents17 = laDateComponents
        laDateComponents17.day = 17
        guard let laDate17 = laCalendar.date(from: laDateComponents17) else {
            XCTFail("LA 날짜(11월 17일) 생성 실패")
            return
        }
        
        // 공통 함수로 과거 시간 검증
        // LA 시간 11월 17일 11:30은 현재 LA 시간 11월 16일 21:30보다 미래이므로 false여야 함
        let isPast = TimezoneConverter.isPastTime(
            hour: 11,
            minute: 30,
            alarmTimezone: laTimezone,
            date: laDate17,
            now: koreaTime
        )
        
        XCTAssertFalse(isPast, "LA 시간 11월 17일 11:30은 현재 시간(11월 16일 21:30)보다 미래여야 합니다")
        
        // 반대로, 11월 16일 11:30은 현재 시간(11월 16일 21:30)보다 과거이므로 true여야 함
        let isPast16 = TimezoneConverter.isPastTime(
            hour: 11,
            minute: 30,
            alarmTimezone: laTimezone,
            date: laDate,
            now: koreaTime
        )
        
        XCTAssertTrue(isPast16, "LA 시간 11월 16일 11:30은 현재 시간(11월 16일 21:30)보다 과거여야 합니다")
    }
}


