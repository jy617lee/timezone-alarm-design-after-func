# 다른 타임존 알람이 울리지 않는 문제 분석

## 문제 상황
- 기기 시간대: LA (America/Los_Angeles, UTC-8)
- 알람 시간대: 한국 (Asia/Seoul, UTC+9)
- 알람 시간: 한국 시간 09:00
- **알람이 울리지 않음**

## 버그 위치

### 1. `findNextAlarmDate` 함수의 날짜 계산 오류 (244번 줄)

**문제 코드:**
```swift
var calendar = Calendar.current
calendar.timeZone = alarmTimezone  // 한국 시간대

// todayAlarmTime은 UTC Date
if let nextDay = calendar.date(byAdding: .day, value: 1, to: todayAlarmTime) {
    // nextDay는 UTC Date인데, calendar.timeZone이 한국 시간대로 설정되어 있음
    // calendar.date(byAdding:)는 calendar.timeZone을 사용하여 Date를 해석함
    // 따라서 UTC Date를 한국 시간대로 해석한 후 하루를 더함 → 잘못된 계산!
}
```

**문제점:**
- `todayAlarmTime`은 UTC Date입니다
- `calendar.timeZone`이 한국 시간대로 설정되어 있습니다
- `calendar.date(byAdding:)`는 `calendar.timeZone`을 사용하여 Date를 해석합니다
- 따라서 UTC Date를 한국 시간대로 해석한 후 하루를 더하는데, 이것이 잘못된 계산입니다

**예시:**
- LA 시간: 11월 18일 16:00 (UTC: 11월 19일 00:00)
- 한국 시간: 11월 19일 09:00
- 한국 알람 시간: 09:00 (이미 지남)

1. `todayAlarmTime` = 한국 11월 19일 09:00 (UTC로 변환된 값, 예: 11월 19일 00:00 UTC)
2. `calendar.timeZone = 한국 시간대`
3. `calendar.date(byAdding: .day, value: 1, to: todayAlarmTime)` 호출:
   - `todayAlarmTime` (UTC)를 한국 시간대로 해석 → 한국 11월 19일 09:00
   - 하루를 더함 → 한국 11월 20일 09:00
   - 이것을 다시 UTC로 변환 → 11월 20일 00:00 UTC
4. `nextDay` = 11월 20일 00:00 UTC (잘못된 값!)

**올바른 계산:**
- `todayAlarmTime` (UTC)에 직접 24시간(86400초)을 더해야 함
- 또는 UTC Calendar를 사용해야 함

### 2. `convertToUTCDate` 호출 시 잘못된 파라미터 (245-249번 줄)

**문제 코드:**
```swift
if let nextAlarmTime = TimezoneConverter.convertToUTCDate(
    alarmHour: alarm.hour,
    alarmMinute: alarm.minute,
    alarmTimezone: alarmTimezone,
    alarmDate: nextDay  // ← nextDay는 UTC Date인데, alarmDate는 "알람 시간대 기준"이어야 함
) {
```

**문제:**
- `nextDay`는 UTC Date입니다
- `convertToUTCDate`의 `alarmDate` 파라미터는 "알람 시간대 기준"이어야 합니다
- `convertToUTCDate` 내부에서 `alarmDate`를 알람 시간대로 해석합니다:
  ```swift
  var alarmCalendar = Calendar.current
  alarmCalendar.timeZone = alarmTimezone
  let alarmDateComponents = alarmCalendar.dateComponents([.year, .month, .day], from: alarmDate)
  ```
- UTC Date를 알람 시간대로 해석하면 잘못된 날짜가 생성됩니다

**예시:**
- `nextDay` = 11월 20일 00:00 UTC
- `alarmTimezone` = 한국 시간대
- `alarmCalendar.dateComponents([.year, .month, .day], from: nextDay)`:
  - UTC 11월 20일 00:00을 한국 시간대로 해석 → 한국 11월 20일 09:00
  - 날짜만 추출 → 11월 20일
- 결과: 한국 11월 20일 09:00 (의도한 값이 아님!)

## 왜 이 버그를 못 잡았는가?

### 테스트 코드의 문제

1. **실제 기기 시간대 변경을 시뮬레이션하지 않음**
   - 테스트 코드가 실제 기기 시간대 변경을 시뮬레이션하지 않음
   - `Calendar.current`는 항상 시스템 시간대를 사용하므로, 다른 시간대에서의 동작을 검증하지 못함

2. **단위 테스트의 부족**
   - `findNextAlarmDate` 함수에 대한 직접적인 단위 테스트가 없음
   - 날짜 경계 케이스(다음 날로 넘어가는 경우)를 테스트하지 않음

3. **통합 테스트의 부족**
   - 실제 알림 스케줄링부터 트리거까지의 전체 플로우를 테스트하지 않음
   - `UNCalendarNotificationTrigger`가 올바른 시간에 트리거되는지 검증하지 않음

4. **시간대 차이 시나리오 미검증**
   - 기기 시간대와 알람 시간대가 다른 경우를 충분히 테스트하지 않음
   - 특히 날짜 경계를 넘어가는 경우(한국 11월 19일 → LA 11월 18일)를 테스트하지 않음

## 해결 방법 (참고용, 수정하지 말 것)

1. **`findNextAlarmDate` 수정:**
   - UTC Calendar를 사용하여 날짜 계산
   - 또는 UTC Date에 직접 24시간(86400초)을 더함

2. **`convertToUTCDate` 호출 수정:**
   - `nextDay`를 알람 시간대 기준으로 변환한 후 전달
   - 또는 `convertToUTCDate` 함수를 수정하여 UTC Date를 직접 받을 수 있도록 함

3. **테스트 코드 개선:**
   - `findNextAlarmDate`에 대한 직접적인 단위 테스트 추가
   - 실제 기기 시간대 변경을 시뮬레이션하는 테스트 추가
   - 통합 테스트 추가 (실제 알림 스케줄링부터 트리거까지)

