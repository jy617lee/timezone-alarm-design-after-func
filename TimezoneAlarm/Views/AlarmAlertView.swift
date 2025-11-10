//
//  AlarmAlertView.swift
//  TimezoneAlarm
//
//  테스트용 임시 알람 알림 화면
//

import SwiftUI
import AVFoundation
import AudioToolbox
import UserNotifications

struct AlarmAlertView: View {
    let alarm: Alarm
    let onDismiss: () -> Void
    @State private var audioPlayer: AVAudioPlayer?
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
                    // 백그라운드 오디오 재생도 정지
                    NotificationDelegate.shared.stopBackgroundAudioPlayback()
                    // 해당 알람의 모든 체인 알림 취소
                    AlarmScheduler.shared.cancelAlarm(alarm)
                    // 표시된 푸시 알림도 제거
                    AlarmScheduler.shared.removeDeliveredNotification(for: alarm)
                    // dismiss 처리 (추가 체인 알림 예약 방지)
                    NotificationDelegate.shared.dismissAlarm(alarm)
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
        // 30초 오디오 파일을 무한 루프로 재생
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "wav") else {
            debugLog("⚠️ alarm.wav 파일을 찾을 수 없습니다")
            // 폴백: 시스템 알람 사운드 사용
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            soundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                AudioServicesPlaySystemSound(1005)
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            return
        }
        
        do {
            // AVAudioPlayer로 오디오 파일 재생
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // 무한 루프
            audioPlayer?.volume = 1.0 // 최대 볼륨
            audioPlayer?.play()
            debugLog("🔊 알람 사운드 재생 시작 (무한 루프)")
            
            // 진동도 함께 반복 (약 29초마다, 파일 길이에 맞춤)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            soundTimer = Timer.scheduledTimer(withTimeInterval: 29.0, repeats: true) { _ in
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } catch {
            debugLog("❌ 오디오 재생 실패: \(error.localizedDescription)")
            // 폴백: 시스템 알람 사운드 사용
            AudioServicesPlaySystemSound(1005)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            soundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                AudioServicesPlaySystemSound(1005)
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
    
    private func stopAlarm() {
        // 타이머 정지
        soundTimer?.invalidate()
        soundTimer = nil
        
        // 오디오 플레이어 정지 및 정리
        audioPlayer?.stop()
        audioPlayer = nil
        
        debugLog("🔇 알람 사운드 정지")
    }
}

