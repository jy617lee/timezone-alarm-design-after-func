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
                    Image.fromResources("alarm-icon")
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
                    
                    // 도시
                    HStack(spacing: 10) {
                        Text(alarm.countryFlag)
                            .font(.geist(size: 28, weight: .regular))
                        Text(alarm.cityName)
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
        }
        .onDisappear {
            // onDisappear에서는 오디오를 정지하지 않음
            // 백그라운드로 돌아갈 수 있으므로 계속 재생되도록 유지
            // dismiss 버튼을 눌렀을 때만 정지됨
            soundTimer?.invalidate()
            soundTimer = nil
        }
    }
    
    private func stopAlarm() {
        // 타이머 정지 (로컬 타이머는 사용하지 않으므로 정리만)
        soundTimer?.invalidate()
        soundTimer = nil
        
        // 로컬 플레이어 정리 (사용하지 않지만 혹시 모르니)
        audioPlayer?.stop()
        audioPlayer = nil
        
        // 실제 재생은 dismiss 버튼을 눌렀을 때만 정지
        // onDisappear에서는 정지하지 않음 (백그라운드로 돌아갈 수 있으므로)
        debugLog("🔇 AlarmAlertView 사라짐 (오디오는 계속 재생)")
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


