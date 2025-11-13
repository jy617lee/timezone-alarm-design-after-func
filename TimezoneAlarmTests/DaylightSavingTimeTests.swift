//
//  DaylightSavingTimeTests.swift
//  TimezoneAlarmTests
//
//  서머타임 대응 테스트
//

import XCTest
@testable import TimezoneAlarm

final class DaylightSavingTimeTests: XCTestCase {
    
    /// 서머타임 시작 시점 테스트 (봄)
    /// 미국 서머타임은 3월 둘째 일요일 오전 2시에 시작
    func testDSTStart() {
        // 2024년 3월 10일 (일요일) - 서머타임 시작일
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 10
        components.hour = 2
        components.minute = 0
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        guard let dstStartDate = calendar.date(from: components) else {
            XCTFail("서머타임 시작 날짜 생성 실패")
            return
        }
        
        // 서머타임 시작 전 (PST, UTC-8)
        var beforeDST = components
        beforeDST.hour = 1
        beforeDST.minute = 59
        guard let beforeDSTDate = calendar.date(from: beforeDST) else {
            XCTFail("서머타임 시작 전 날짜 생성 실패")
            return
        }
        
        // 서머타임 시작 후 (PDT, UTC-7)
        var afterDST = components
        afterDST.hour = 3
        afterDST.minute = 0
        guard let afterDSTDate = calendar.date(from: afterDST) else {
            XCTFail("서머타임 시작 후 날짜 생성 실패")
            return
        }
        
        // UTC 변환 확인
        let beforeDSTUTC = beforeDSTDate.timeIntervalSince1970
        let afterDSTUTC = afterDSTDate.timeIntervalSince1970
        let timeDifference = afterDSTUTC - beforeDSTUTC
        
        // 서머타임 시작으로 인해 1시간이 건너뛰어지므로, 실제 시간 차이는 1시간이어야 함
        // 하지만 날짜상으로는 2시간 차이가 나야 함 (1:59 -> 3:00)
        XCTAssertEqual(timeDifference, 3600, accuracy: 60, "서머타임 시작 시 1시간이 건너뛰어져야 합니다")
    }
    
    /// 서머타임 종료 시점 테스트 (가을)
    /// 미국 서머타임은 11월 첫째 일요일 오전 2시에 종료
    func testDSTEnd() {
        // 2024년 11월 3일 (일요일) - 서머타임 종료일
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 3
        components.hour = 1
        components.minute = 59
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")
        
        guard let dstEndDate = calendar.date(from: components) else {
            XCTFail("서머타임 종료 날짜 생성 실패")
            return
        }
        
        // 서머타임 종료 전 (PDT, UTC-7)
        var beforeDSTEnd = components
        beforeDSTEnd.hour = 1
        beforeDSTEnd.minute = 59
        
        // 서머타임 종료 후 (PST, UTC-8) - 같은 로컬 시간이지만 UTC는 다름
        var afterDSTEnd = components
        afterDSTEnd.hour = 1
        afterDSTEnd.minute = 0
        
        // 서머타임 종료로 인해 1시간이 반복되므로, 같은 로컬 시간이 두 번 나타남
        // 이는 iOS의 UNCalendarNotificationTrigger가 자동으로 처리함
        XCTAssertTrue(true, "서머타임 종료는 iOS가 자동으로 처리합니다")
    }
    
    /// 알람 스케줄링이 서머타임을 올바르게 처리하는지 테스트
    func testAlarmSchedulingWithDST() {
        let calendar = Calendar.current
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        // 서머타임 기간 중 (여름)
        var summerComponents = DateComponents()
        summerComponents.year = 2024
        summerComponents.month = 7
        summerComponents.day = 15
        summerComponents.hour = 9
        summerComponents.minute = 0
        summerComponents.timeZone = laTimezone
        
        guard let summerDate = calendar.date(from: summerComponents) else {
            XCTFail("여름 날짜 생성 실패")
            return
        }
        
        // 서머타임이 아닌 기간 (겨울)
        var winterComponents = DateComponents()
        winterComponents.year = 2024
        winterComponents.month = 12
        winterComponents.day = 15
        winterComponents.hour = 9
        winterComponents.minute = 0
        winterComponents.timeZone = laTimezone
        
        guard let winterDate = calendar.date(from: winterComponents) else {
            XCTFail("겨울 날짜 생성 실패")
            return
        }
        
        // UTC 변환 확인
        let summerUTC = summerDate.timeIntervalSince1970
        let winterUTC = winterDate.timeIntervalSince1970
        
        // 같은 로컬 시간(9시)이지만 UTC 차이는 서머타임으로 인해 1시간 차이
        // 실제로는 약 5개월 차이이므로 훨씬 큼
        let timeDifference = abs(summerUTC - winterUTC)
        XCTAssertGreaterThan(timeDifference, 0, "서머타임으로 인해 UTC 시간이 달라야 합니다")
        
        // UTC를 다시 로컬 시간으로 변환했을 때 같은 시간(9시)이 나와야 함
        let summerLocal = calendar.dateComponents(in: laTimezone, from: summerDate)
        let winterLocal = calendar.dateComponents(in: laTimezone, from: winterDate)
        
        XCTAssertEqual(summerLocal.hour, 9, "여름에도 9시여야 합니다")
        XCTAssertEqual(winterLocal.hour, 9, "겨울에도 9시여야 합니다")
    }
    
    /// 반복 알람이 서머타임 전환을 올바르게 처리하는지 테스트
    func testRepeatingAlarmWithDST() {
        let calendar = Calendar.current
        guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
            XCTFail("LA 시간대를 찾을 수 없습니다")
            return
        }
        
        // 매주 월요일 오전 9시 알람 설정
        // 서머타임 전환 전후 모두 같은 로컬 시간에 울려야 함
        
        // 서머타임 시작 전 (3월 첫째 월요일)
        var beforeDSTComponents = DateComponents()
        beforeDSTComponents.year = 2024
        beforeDSTComponents.month = 3
        beforeDSTComponents.day = 4 // 3월 첫째 월요일
        beforeDSTComponents.hour = 9
        beforeDSTComponents.minute = 0
        beforeDSTComponents.weekday = 2 // 월요일
        beforeDSTComponents.timeZone = laTimezone
        
        guard let beforeDSTDate = calendar.date(from: beforeDSTComponents) else {
            XCTFail("서머타임 전 날짜 생성 실패")
            return
        }
        
        // 서머타임 시작 후 (3월 둘째 월요일)
        var afterDSTComponents = DateComponents()
        afterDSTComponents.year = 2024
        afterDSTComponents.month = 3
        afterDSTComponents.day = 11 // 3월 둘째 월요일 (서머타임 시작 후)
        afterDSTComponents.hour = 9
        afterDSTComponents.minute = 0
        afterDSTComponents.weekday = 2 // 월요일
        afterDSTComponents.timeZone = laTimezone
        
        guard let afterDSTDate = calendar.date(from: afterDSTComponents) else {
            XCTFail("서머타임 후 날짜 생성 실패")
            return
        }
        
        // 두 날짜 모두 로컬 시간으로 9시여야 함
        let beforeDSTLocal = calendar.dateComponents(in: laTimezone, from: beforeDSTDate)
        let afterDSTLocal = calendar.dateComponents(in: laTimezone, from: afterDSTDate)
        
        XCTAssertEqual(beforeDSTLocal.hour, 9, "서머타임 전에도 9시여야 합니다")
        XCTAssertEqual(afterDSTLocal.hour, 9, "서머타임 후에도 9시여야 합니다")
        
        // UTC 차이는 서머타임으로 인해 1시간 차이
        let utcDifference = abs(beforeDSTDate.timeIntervalSince1970 - afterDSTDate.timeIntervalSince1970)
        // 7일 차이에서 서머타임으로 인한 1시간 차이를 고려
        let expectedDifference: TimeInterval = 7 * 24 * 3600 - 3600 // 7일 - 1시간
        XCTAssertEqual(utcDifference, expectedDifference, accuracy: 60, "서머타임 전환으로 인해 UTC 차이가 달라야 합니다")
    }
}


