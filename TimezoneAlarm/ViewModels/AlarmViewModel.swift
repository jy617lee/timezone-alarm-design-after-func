//
//  AlarmViewModel.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation
import SwiftUI

@MainActor
class AlarmViewModel: ObservableObject {
    @Published var activeAlarm: Alarm? = nil
    @Published var alarms: [Alarm] = [] {
        didSet {
            // 알람이 변경될 때마다 저장
            saveAlarms()
        }
    }
    
    private let alarmsKey = "savedAlarms"
    
    init() {
        // 저장된 알람 로드
        loadAlarms()
        
        // 앱 시작 시 스케줄링 확인 및 재스케줄링
        Task { @MainActor in
            await verifyAndRescheduleOnAppStart()
        }
        
        // 타임존 변경 감지
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            debugLog("🕐 시스템 타임존 변경 감지 - 알람 재스케줄링")
            Task { @MainActor in
                self?.rescheduleAllAlarms()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // 앱 시작 시 스케줄링 확인 및 재스케줄링
    private func verifyAndRescheduleOnAppStart() async {
        debugLog("📋 앱 시작 시 스케줄링 확인 시작")
        
        // 권한 확인
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            debugLog("⚠️ 알림 권한이 없어 스케줄링 확인을 건너뜁니다")
            return
        }
        
        // 스케줄링 확인 및 필요시 재스케줄링
        AlarmScheduler.shared.verifyAndRescheduleIfNeeded(alarms: alarms) { rescheduledCount in
            if rescheduledCount > 0 {
                debugLog("✅ \(rescheduledCount)개의 알람을 재스케줄링했습니다")
            }
        }
    }
    
    // 모든 알람 재스케줄링 (타임존 변경 시)
    func rescheduleAllAlarms() {
        debugLog("🔄 모든 알람 재스케줄링 시작 (활성화된 알람: \(alarms.filter { $0.isEnabled }.count)개)")
        for alarm in alarms where alarm.isEnabled {
            AlarmScheduler.shared.scheduleAlarm(alarm)
        }
    }
    
    // 저장된 알람 로드
    private func loadAlarms() {
        // 초기 설정이 완료되지 않았으면 알람을 비움
        let hasCompletedInitialSetup = UserDefaults.standard.bool(forKey: "hasCompletedInitialSetup")
        if !hasCompletedInitialSetup {
            alarms = []
            // 저장된 알람 데이터도 삭제
            UserDefaults.standard.removeObject(forKey: alarmsKey)
            return
        }
        
        guard let data = UserDefaults.standard.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else {
            // 저장된 데이터가 없으면 빈 배열로 시작 (샘플 데이터 로드하지 않음)
            alarms = []
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
            let wasEnabled = alarms[index].isEnabled
            alarms[index].isEnabled.toggle()
            
            let newState = alarms[index].isEnabled
            
            // 알람이 비활성화되면 스케줄링 취소
            if wasEnabled && !newState {
                AlarmScheduler.shared.cancelAlarm(alarms[index])
            } else if !wasEnabled && newState {
                // 알람이 활성화되면 스케줄링
                AlarmScheduler.shared.scheduleAlarm(alarms[index])
            }
            
            // Analytics 로깅
            AnalyticsService.shared.logAlarmToggled(alarm: alarms[index], isEnabled: newState)
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        // Analytics 로깅 (삭제 전에 로깅)
        AnalyticsService.shared.logAlarmDeleted(alarm: alarm)
        
        // 알림 스케줄링 취소
        AlarmScheduler.shared.cancelAlarm(alarm)
        // 알람 삭제
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
        
        // 알람이 활성화되어 있으면 스케줄링
        if newAlarm.isEnabled {
            AlarmScheduler.shared.scheduleAlarm(newAlarm)
        }
        
        // Analytics 로깅
        AnalyticsService.shared.logAlarmCreated(alarm: newAlarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            let oldAlarm = alarms[index]
            alarms[index] = alarm
            
            // 기존 알림 취소 후 재스케줄링
            AlarmScheduler.shared.cancelAlarm(oldAlarm)
            if alarm.isEnabled {
                AlarmScheduler.shared.scheduleAlarm(alarm)
            }
            
            // 알람이 수정되면 dismiss 상태 초기화 (새로운 알람으로 봄)
            NotificationDelegate.shared.clearDismissedStatus(for: alarm.id)
            
            // Analytics 로깅
            AnalyticsService.shared.logAlarmUpdated(alarm: alarm)
        }
    }
}

