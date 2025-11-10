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
    @State private var showCustomNotification = false
    @State private var notificationAlarm: Alarm?
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    
    private var hasDefaultCountry: Bool {
        UserDefaults.standard.string(forKey: "defaultCountryId") != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 그라데이션 백그라운드
                LinearGradient(
                    colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 커스텀 헤더 (배경색, 블러, 그림자 적용)
                    HStack {
                        Text("Syncly")
                            .font(.geist(size: 24, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        if viewModel.alarms.isEmpty {
                            // Empty State - 버튼만 표시
                            HStack(spacing: 12) {
                                Button(action: {
                                    showAlarmForm = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.geist(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.appPrimary))
                                }
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image(systemName: "gearshape")
                                        .font(.geist(size: 18, weight: .medium))
                                        .foregroundColor(.appTextPrimary)
                                        .frame(width: 36, height: 36)
                                }
                            }
                            .padding(.trailing, 20)
                        } else {
                            // Alarm List
                            if editMode == .active {
                                Button(NSLocalizedString("button.done", comment: "Done button")) {
                                    withAnimation {
                                        editMode = .inactive
                                    }
                                }
                                .font(.geist(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.appPrimary)
                                .cornerRadius(20)
                                .padding(.trailing, 20)
                            } else {
                                HStack(spacing: 12) {
                                    #if DEBUG
                                    // 테스트용 알람 실행 화면 버튼 (개발용만)
                                    Button(action: {
                                        let testAlarm = Alarm(
                                            name: "Test Alarm",
                                            hour: 7,
                                            minute: 30,
                                            timezoneIdentifier: "Asia/Seoul",
                                            countryName: "South Korea",
                                            countryFlag: "🇰🇷"
                                        )
                                        viewModel.activeAlarm = testAlarm
                                        
                                        // 푸시 알림도 즉시 트리거
                                        let content = UNMutableNotificationContent()
                                        content.title = testAlarm.name
                                        content.body = "\(testAlarm.formattedTime) - \(testAlarm.countryFlag) \(testAlarm.countryName)"
                                        content.sound = UNNotificationSound(named: UNNotificationSoundName("alarm.wav"))
                                        if #available(iOS 15.0, *) {
                                            content.interruptionLevel = .timeSensitive
                                        }
                                        content.userInfo = [
                                            "alarmId": testAlarm.id.uuidString,
                                            "alarmName": testAlarm.name,
                                            "alarmHour": testAlarm.hour,
                                            "alarmMinute": testAlarm.minute,
                                            "timezoneIdentifier": testAlarm.timezoneIdentifier,
                                            "countryName": testAlarm.countryName,
                                            "countryFlag": testAlarm.countryFlag
                                        ]
                                        
                                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                                        let request = UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger)
                                        UNUserNotificationCenter.current().add(request)
                                    }) {
                                        Image(systemName: "bell.fill")
                                            .font(.geist(size: 16, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                            .frame(width: 36, height: 36)
                                    }
                                    #endif
                                    Button(action: {
                                        showAlarmForm = true
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.geist(size: 18, weight: .medium))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(Circle().fill(Color.appPrimary))
                                    }
                                    Button(action: {
                                        showSettings = true
                                    }) {
                                        Image(systemName: "gearshape")
                                            .font(.geist(size: 18, weight: .medium))
                                            .foregroundColor(.appTextPrimary)
                                            .frame(width: 36, height: 36)
                                    }
                                }
                                .padding(.trailing, 20)
                            }
                        }
                    }
                    .frame(height: 44)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.appHeaderBackground)
                    .background(.ultraThinMaterial)
                    .shadow(color: Color.appShadow.opacity(0.3), radius: 16, x: 0, y: 4)
                
                // 컨텐츠
                if viewModel.alarms.isEmpty {
                    // Empty State
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            Spacer()
                                .frame(height: geometry.size.height * 0.16) // top에서 전체 height의 16%
                            
                        // 알람 아이콘
                        Image("alarm-icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            
                            // Title
                            Text(NSLocalizedString("content.empty.title", comment: "No alarms yet title"))
                                .font(.geist(size: 28, weight: .bold))
                                .foregroundColor(.appTextPrimary)
                                .padding(.top, 24)
                            
                            // Description
                            Text(NSLocalizedString("content.empty.description", comment: "Tap to add first alarm"))
                                .font(.geist(size: 20, weight: .regular))
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.top, 8)
                            
                            // Add New Alarm 버튼
                            Button(action: {
                                showAlarmForm = true
                            }) {
                                Text(NSLocalizedString("content.empty.add_button", comment: "Add new alarm button"))
                                    .font(.geist(size: 17, weight: .semibold))
                                    .foregroundColor(.appTextOnPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.appPrimary)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 32) // 간격 더 띄움
                            
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    // Alarm List
                    AlarmListView(viewModel: viewModel, showAlarmForm: $showAlarmForm, showSettings: $showSettings, editMode: $editMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
                // 커스텀 알림 뷰 표시 (체인 알림이 계속 도착하면서 계속 표시됨)
                notificationAlarm = newValue
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCustomNotification = true
                }
                showAlarmAlert = true
            } else {
                // activeAlarm이 nil이 되면 커스텀 알림 뷰 숨김
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCustomNotification = false
                }
                notificationAlarm = nil
            }
        }
        .overlay(alignment: .top) {
            // 커스텀 알림 뷰 (분홍색 배경, Geist 폰트)
            if showCustomNotification, let alarm = notificationAlarm {
                CustomNotificationView(alarm: alarm)
                    .transition(.move(edge: .top).combined(with: .opacity))
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

// 커스텀 알림 뷰 (연한 분홍색 배경, Geist 폰트)
struct CustomNotificationView: View {
    let alarm: Alarm
    
    var body: some View {
        HStack(spacing: 12) {
            // 알람 아이콘
            Image("alarm-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                // 알람명 (타이틀)
                Text(alarm.name)
                    .font(.geist(size: 18, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                
                // 시간 및 국가 (description)
                Text("\(alarm.formattedTime) - \(alarm.countryFlag) \(alarm.countryName)")
                    .font(.geist(size: 13, weight: .regular))
                    .foregroundColor(.appTextPrimary.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackgroundTop)
        .cornerRadius(12)
        .shadow(color: Color.appShadow.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ContentView()
}

