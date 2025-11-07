//
//  Alarm.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation

struct Alarm: Identifiable, Codable {
    let id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var timezoneIdentifier: String
    var countryName: String
    var countryFlag: String
    var selectedWeekdays: Set<Int> // 1=Sunday, 2=Monday, ..., 7=Saturday
    var isEnabled: Bool
    var createdAt: Date
    var sortOrder: Int // 드래그 앤 드롭으로 변경된 순서
    
    init(
        id: UUID = UUID(),
        name: String,
        hour: Int,
        minute: Int,
        timezoneIdentifier: String,
        countryName: String,
        countryFlag: String,
        selectedWeekdays: Set<Int> = [],
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.timezoneIdentifier = timezoneIdentifier
        self.countryName = countryName
        self.countryFlag = countryFlag
        self.selectedWeekdays = selectedWeekdays
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
}

