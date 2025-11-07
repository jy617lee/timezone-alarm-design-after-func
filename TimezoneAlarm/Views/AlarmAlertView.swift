//
//  AlarmAlertView.swift
//  TimezoneAlarm
//
//  테스트용 임시 알람 알림 화면
//

import SwiftUI
import AVFoundation
import AudioToolbox

struct AlarmAlertView: View {
    let alarm: Alarm
    let onDismiss: () -> Void
    @State private var soundTimer: Timer?
    
    var body: some View {
        ZStack {
            // 배경색
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 알람 아이콘
                Image(systemName: "bell.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.red)
                
                // 알람명
                Text(alarm.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // 시간
                Text(alarm.formattedTime)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
                
                // 국가
                HStack(spacing: 10) {
                    Text(alarm.countryFlag)
                        .font(.largeTitle)
                    Text(alarm.countryName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // 해제 버튼
                Button(action: {
                    stopAlarm()
                    onDismiss()
                }) {
                    Text("Dismiss")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            playAlarmSound()
        }
        .onDisappear {
            stopAlarm()
        }
    }
    
    private func playAlarmSound() {
        // 시스템 기본 알람 사운드 재생
        AudioServicesPlaySystemSound(1005) // 알람 사운드
        
        // 반복 재생을 위해 타이머 사용
        soundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    private func stopAlarm() {
        soundTimer?.invalidate()
        soundTimer = nil
    }
}

