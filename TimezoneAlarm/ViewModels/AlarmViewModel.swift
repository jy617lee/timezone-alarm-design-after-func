//
//  AlarmViewModel.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation
import SwiftUI

@Observable
class AlarmViewModel {
    var alarms: [Alarm] = []
    
    init() {
        // 테스트용 샘플 데이터
        loadSampleData()
    }
    
    private func loadSampleData() {
        alarms = [
            Alarm(
                name: "Morning Wake Up",
                hour: 7,
                minute: 30,
                timezoneIdentifier: "Asia/Seoul",
                countryName: "South Korea",
                countryFlag: "🇰🇷",
                selectedWeekdays: [2, 3, 4, 5, 6], // 월-금
                isEnabled: true,
                createdAt: Date().addingTimeInterval(-86400),
                sortOrder: 0
            ),
            Alarm(
                name: "Evening Reminder",
                hour: 9,
                minute: 0,
                timezoneIdentifier: "America/New_York",
                countryName: "United States",
                countryFlag: "🇺🇸",
                selectedWeekdays: [1, 7], // 일, 토
                isEnabled: true,
                createdAt: Date(),
                sortOrder: 1
            )
        ]
    }
    
    // 생성일 기준 최신순 정렬 (sortOrder가 같으면)
    var sortedAlarms: [Alarm] {
        alarms.sorted { alarm1, alarm2 in
            if alarm1.sortOrder != alarm2.sortOrder {
                return alarm1.sortOrder < alarm2.sortOrder
            }
            return alarm1.createdAt > alarm2.createdAt
        }
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isEnabled.toggle()
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll { $0.id == alarm.id }
    }
    
    func moveAlarm(from source: IndexSet, to destination: Int) {
        alarms.move(fromOffsets: source, toOffset: destination)
        // sortOrder 업데이트
        for (index, _) in alarms.enumerated() {
            alarms[index].sortOrder = index
        }
    }
}

