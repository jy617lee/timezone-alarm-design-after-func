//
//  SilentModeNotificationView.swift
//  TimezoneAlarm
//
//  무음모드/방해금지모드 안내 팝업
//

import SwiftUI

struct SilentModeNotificationView: View {
    let onDismiss: () -> Void
    let onConfirm: () -> Void
    
    var title: String {
        NSLocalizedString("silent_mode_notification.title", comment: "Alarm not sounding title")
    }
    
    var description: String {
        NSLocalizedString("silent_mode_notification.description", comment: "Silent mode or Do Not Disturb mode description")
    }
    
    var body: some View {
        ZStack {
            // 배경 오버레이
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 팝업 컨텐츠
            VStack(spacing: 0) {
                // 상단 X 버튼
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
                
                // 메인 컨텐츠
                VStack(spacing: 20) {
                    // 제목
                    Text(title)
                        .font(.geist(size: 22, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // 설명 텍스트
                    Text(description)
                        .font(.geist(size: 16, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                    
                    // 이미지 (한/영/JP 각각 다르게 제공될 예정)
                    Image("alarm-not-sounding-image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .padding(.vertical, 20)
                    
                    // 확인 버튼
                    Button(action: onConfirm) {
                        Text(NSLocalizedString("silent_mode_notification.button.confirm", comment: "Confirm button"))
                            .font(.geist(size: 17, weight: .semibold))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.appCardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 30)
        }
    }
}

#Preview {
    SilentModeNotificationView(
        onDismiss: {},
        onConfirm: {}
    )
}

