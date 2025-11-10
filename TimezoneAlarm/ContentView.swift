//
//  ContentView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var showAlarmForm = false
    @State private var showAlarmAlert = false
    @State private var showSettings = false
    @State private var editMode: EditMode = .inactive
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    
    private var hasDefaultCountry: Bool {
        UserDefaults.standard.string(forKey: "defaultCountryId") != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 커스텀 헤더
                HStack {
                    Spacer()
                    if viewModel.alarms.isEmpty {
                        // Empty State - 버튼만 표시
                        HStack(spacing: 12) {
                            Button(action: {
                                showAlarmForm = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color(.systemGray6)))
                            }
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color(.systemGray6)))
                            }
                        }
                        .padding(.trailing, 16)
                    } else {
                        // Alarm List
                        if editMode == .active {
                            Button("Done") {
                                withAnimation {
                                    editMode = .inactive
                                }
                            }
                            .padding(.trailing, 16)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: {
                                    showAlarmForm = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(.systemGray6)))
                                }
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Color(.systemGray6)))
                                }
                            }
                            .padding(.trailing, 16)
                        }
                    }
                }
                .frame(height: 44)
                .background(Color(.systemBackground))
                
                // 컨텐츠
                if viewModel.alarms.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // 알람 아이콘
                        Image(systemName: "alarm")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)
                        
                        // Title
                        Text("No Alarms Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Description
                        Text("Tap + to add your first alarm")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        // Add New Alarm 버튼
                        Button(action: {
                            showAlarmForm = true
                        }) {
                            Text("Add New Alarm")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // Alarm List
                    AlarmListView(viewModel: viewModel, showAlarmForm: $showAlarmForm, showSettings: $showSettings, editMode: $editMode)
                }
            }
            .sheet(isPresented: $showAlarmForm) {
                AlarmFormView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            // 앱이 포그라운드로 올 때 최근 알림 확인 (백그라운드에서 알림이 왔을 때 처리)
            // 약간의 지연을 두어 ContentView가 완전히 준비된 후에 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkRecentNotifications()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 앱이 백그라운드에서 포그라운드로 올 때 최근 알림 확인
            // 약간의 지연을 두어 ContentView가 완전히 준비된 후에 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkRecentNotifications()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 앱이 활성화될 때도 최근 알림 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkRecentNotifications()
            }
        }
        .onChange(of: viewModel.activeAlarm) { oldValue, newValue in
            debugLog("🔄 viewModel.activeAlarm 변경: \(oldValue?.name ?? "nil") -> \(newValue?.name ?? "nil")")
            if newValue != nil {
                debugLog("🔔 알람 알림 화면 표시: \(newValue?.name ?? "Unknown")")
                showAlarmAlert = true
            }
        }
        .onChange(of: notificationDelegate.activeAlarm) { oldValue, newValue in
            debugLog("🔄 notificationDelegate.activeAlarm 변경: \(oldValue?.name ?? "nil") -> \(newValue?.name ?? "nil")")
            if newValue != nil {
                debugLog("🔔 알림에서 알람 실행: \(newValue?.name ?? "Unknown")")
                showAlarmAlert = true
            }
        }
        .fullScreenCover(isPresented: $showAlarmAlert) {
            if let alarm = viewModel.activeAlarm ?? notificationDelegate.activeAlarm {
                AlarmAlertView(alarm: alarm) {
                    viewModel.activeAlarm = nil
                    notificationDelegate.activeAlarm = nil
                    showAlarmAlert = false
                }
            }
        }
    }
    
    // 최근 알림 확인 (백그라운드에서 알림이 왔을 때 처리)
    private func checkRecentNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            // 최근 알람 알림 찾기 (30초 이내 - 백그라운드 오디오가 계속 재생되도록)
            let now = Date()
            for notification in notifications {
                if let alarmId = notification.request.content.userInfo["alarmId"] as? String,
                   let alarmName = notification.request.content.userInfo["alarmName"] as? String,
                   let alarmHour = notification.request.content.userInfo["alarmHour"] as? Int,
                   let alarmMinute = notification.request.content.userInfo["alarmMinute"] as? Int,
                   let timezoneIdentifier = notification.request.content.userInfo["timezoneIdentifier"] as? String,
                   let countryName = notification.request.content.userInfo["countryName"] as? String,
                   let countryFlag = notification.request.content.userInfo["countryFlag"] as? String {
                    
                    // 알림이 최근 30초 이내에 도착했는지 확인 (백그라운드 오디오 유지)
                    let notificationDate = notification.date
                    let timeSinceNotification = now.timeIntervalSince(notificationDate)
                    
                    if timeSinceNotification <= 30.0 {
                        debugLog("🔔 최근 알람 알림 발견: \(alarmName) (도착 후 \(String(format: "%.1f", timeSinceNotification))초 경과)")
                        
                        let alarm = Alarm(
                            id: UUID(uuidString: alarmId) ?? UUID(),
                            name: alarmName,
                            hour: alarmHour,
                            minute: alarmMinute,
                            timezoneIdentifier: timezoneIdentifier,
                            countryName: countryName,
                            countryFlag: countryFlag
                        )
                        
                        Task { @MainActor in
                            notificationDelegate.activeAlarm = alarm
                            // 백그라운드에서도 연속 사운드 재생 시작 (이미 재생 중이면 재시작하지 않음)
                            notificationDelegate.startBackgroundAudioPlayback(for: alarm)
                            // 표시된 알림 제거하지 않음 (계속 표시되어야 함)
                        }
                        
                        // 첫 번째 알람만 처리
                        break
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

