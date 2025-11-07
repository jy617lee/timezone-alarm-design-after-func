//
//  ContentView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var showAlarmForm = false
    @State private var showAlarmAlert = false
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    
    var body: some View {
        NavigationView {
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
                .navigationTitle("Alarms")
                .sheet(isPresented: $showAlarmForm) {
                    AlarmFormView(viewModel: viewModel)
                }
            } else {
                // Alarm List
                AlarmListView(viewModel: viewModel, showAlarmForm: $showAlarmForm)
                    .navigationTitle("Alarms")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showAlarmForm = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showAlarmForm) {
                        AlarmFormView(viewModel: viewModel)
                    }
            }
        }
        .onAppear {
            // 앱이 포그라운드로 올 때 알람 재스케줄링 (타임존 변경 대응)
            viewModel.rescheduleAllAlarms()
        }
        .onChange(of: viewModel.activeAlarm) { oldValue, newValue in
            if newValue != nil {
                print("🔔 알람 알림 화면 표시: \(newValue?.name ?? "Unknown")")
                showAlarmAlert = true
            }
        }
        .onChange(of: notificationDelegate.activeAlarm) { oldValue, newValue in
            if newValue != nil {
                print("🔔 알림에서 알람 실행: \(newValue?.name ?? "Unknown")")
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
}

#Preview {
    ContentView()
}

