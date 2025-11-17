#!/usr/bin/env swift

//
//  test-timezone-conversion.swift
//  TimezoneAlarm
//
//  타임존 변환 로직 검증 스크립트
//  프리커밋 훅에서 실행됨
//

import Foundation

// 서울 시간대
guard let seoulTimezone = TimeZone(identifier: "Asia/Seoul") else {
    print("❌ 서울 시간대를 찾을 수 없습니다")
    exit(1)
}

// LA 시간대
guard let laTimezone = TimeZone(identifier: "America/Los_Angeles") else {
    print("❌ LA 시간대를 찾을 수 없습니다")
    exit(1)
}

let calendar = Calendar.current
let now = Date()

print("🧪 타임존 변환 로직 테스트")
print("=" * 50)

// 시나리오: 서울에서 매주 목요일 오전 9시 알람 설정
// alarmTimezone = Asia/Seoul, hour = 9, minute = 0, weekday = 5 (목요일)

print("\n📋 시나리오:")
print("   1. 서울에서 매주 목요일 오전 9시 알람 설정")
print("   2. LA로 이동")
print("   3. 한국 시간 목요일 오전 9시에 알람이 울려야 함")

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
    print("❌ 서울 시간 UTC 변환 실패")
    exit(1)
}

// UTC를 LA 시간대로 변환 (AlarmScheduler 로직)
var laComponents = calendar.dateComponents(in: laTimezone, from: seoulTimeUTC)
laComponents.second = 0

guard let laDate = calendar.date(from: laComponents) else {
    print("❌ LA 날짜 생성 실패")
    exit(1)
}

// 검증: LA 시간으로 스케줄링된 알람이 서울 시간 목요일 9시에 울리는지 확인
let seoulTimeAtAlarm = calendar.dateComponents(in: seoulTimezone, from: laDate)
let isCorrect = seoulTimeAtAlarm.hour == 9 && seoulTimeAtAlarm.minute == 0 && seoulTimeAtAlarm.weekday == 5

print("\n✅ 검증 결과:")
if isCorrect {
    print("   ✅ 성공: LA 시간으로 스케줄링된 알람이")
    print("      서울 시간 목요일 오전 9시에 정확히 울립니다!")
    print("=" * 50)
    exit(0)
} else {
    print("   ❌ 실패: 서울 시간 \(seoulTimeAtAlarm.hour ?? 0):\(String(format: "%02d", seoulTimeAtAlarm.minute ?? 0)), 요일: \(seoulTimeAtAlarm.weekday ?? 0)")
    print("=" * 50)
    exit(1)
}

// String extension for repeating
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}


