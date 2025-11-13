//
//  Alarm.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var timezoneIdentifier: String
    var cityName: String // 도시 이름
    var countryName: String
    var countryFlag: String
    var selectedWeekdays: Set<Int> // 1=Sunday, 2=Monday, ..., 7=Saturday
    var selectedDate: Date? // 날짜 선택 (반복과 상호배타적)
    var isEnabled: Bool
    var createdAt: Date
    var sortOrder: Int // 드래그 앤 드롭으로 변경된 순서
    
    init(
        id: UUID = UUID(),
        name: String,
        hour: Int,
        minute: Int,
        timezoneIdentifier: String,
        cityName: String,
        countryName: String,
        countryFlag: String,
        selectedWeekdays: Set<Int> = [],
        selectedDate: Date? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.timezoneIdentifier = timezoneIdentifier
        self.cityName = cityName
        self.countryName = countryName
        self.countryFlag = countryFlag
        self.selectedWeekdays = selectedWeekdays
        self.selectedDate = selectedDate
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
    
    // 시간을 AM/PM 형식으로 포맷
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }
    
    // 시간만 (AM/PM 제외)
    var timeOnly: String {
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d", displayHour, minute)
    }
    
    // AM/PM만
    var amPm: String {
        return hour >= 12 ? "PM" : "AM"
    }
    
    // Equatable 구현
    static func == (lhs: Alarm, rhs: Alarm) -> Bool {
        lhs.id == rhs.id
    }
}

