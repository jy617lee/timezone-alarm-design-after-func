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
    @State private var iconScale: CGFloat = 1.0
    @State private var cardOpacity: Double = 0.0
    @State private var cardScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            // 그라데이션 백그라운드 (메인/설정 화면과 동일)
            LinearGradient(
                colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 카드 스타일 컨텐츠
                VStack(spacing: 24) {
                    // 알람 아이콘 (펄스 애니메이션)
                    Image("alarm-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconScale)
                        .padding(.top, 40)
                    
                    // 알람명
                    Text(alarm.name)
                        .font(.geist(size: 28, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    // 시간
                    Text(alarm.formattedTime)
                        .font(.geist(size: 56, weight: .light))
                        .foregroundColor(.appTextPrimary)
                    
                    // 국가
                    HStack(spacing: 10) {
                        Text(alarm.countryFlag)
                            .font(.geist(size: 28, weight: .regular))
                        Text(alarm.countryName)
                            .font(.geist(size: 18, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.bottom, 20)
                    
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
                        Text(NSLocalizedString("button.dismiss", comment: "Dismiss button"))
                            .font(.geist(size: 17, weight: .semibold))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: 448)
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
                .background(Color.appCardBackground)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.appCardBorder, lineWidth: 1)
                )
                .shadow(color: Color.appShadow.opacity(0.3), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 16)
                .opacity(cardOpacity)
                .scaleEffect(cardScale)
                
                Spacer()
            }
        }
        .onAppear {
            // 카드 등장 애니메이션
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardOpacity = 1.0
                cardScale = 1.0
            }
            
            // 아이콘 펄스 애니메이션 시작
            startPulseAnimation()
            
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
    
    private func startPulseAnimation() {
        // 펄스 애니메이션: 1.0 -> 1.15 -> 1.0 반복
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            iconScale = 1.15
        }
    }
}


