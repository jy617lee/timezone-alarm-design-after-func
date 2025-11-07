//
//  AlarmViewModel.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class AlarmViewModel {
    // 테스트용: 5초 후 실행될 알람
    var activeAlarm: Alarm? = nil
    var alarms: [Alarm] = [] {
        didSet {
            // 알람이 변경될 때마다 저장
            saveAlarms()
        }
    }
    
    private let alarmsKey = "savedAlarms"
    
    init() {
        // 저장된 알람 로드
        loadAlarms()
        
        // 타임존 변경 감지
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🕐 시스템 타임존 변경 감지 - 알람 재스케줄링")
            Task { @MainActor in
                self?.rescheduleAllAlarms()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 모든 알람 재스케줄링 (타임존 변경 시)
    func rescheduleAllAlarms() {
        for alarm in alarms where alarm.isEnabled {
            AlarmScheduler.shared.scheduleTestAlarm(alarm)
        }
    }
    
    // 저장된 알람 로드
    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else {
            // 저장된 데이터가 없으면 샘플 데이터 로드
            loadSampleData()
            return
        }
        alarms = decoded
    }
    
    // 알람 저장
    private func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: alarmsKey)
        }
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
    
    func addAlarm(_ alarm: Alarm) {
        var newAlarm = alarm
        newAlarm.sortOrder = alarms.count
        alarms.append(newAlarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        }
    }
    
    // 테스트용: 5초 후 알람 실행 (로컬 알림 사용)
    func scheduleTestAlarm(_ alarm: Alarm) {
        AlarmScheduler.shared.scheduleTestAlarm(alarm)
    }
}

