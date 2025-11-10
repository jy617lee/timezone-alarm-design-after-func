//
//  AlarmCardView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct AlarmCardView: View {
    let alarm: Alarm
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTap: (() -> Void)?
    let index: Int // 카드 색상 순서를 위한 인덱스
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let weekdayIndices = [1, 2, 3, 4, 5, 6, 7] // Sunday=1, Monday=2, ..., Saturday=7
    
    // 카드 색상 팔레트 선택 (인덱스 기반으로 순서대로)
    // 순서: 핫핑크 > 피스타치오 > 오렌지 > 베리 > 레몬 > 쿠키 > 딸기 > 연한갈색
    private var cardPalette: (background: Color, accent: Color) {
        let palettes: [(background: Color, accent: Color)] = [
            (.cardHotPinkBackground, .cardHotPinkAccent),
            (.cardPistachioBackground, .cardPistachioAccent),
            (.cardOrangeBackground, .cardOrangeAccent),
            (.cardBerryBackground, .cardBerryAccent),
            (.cardLemonBackground, .cardLemonAccent),
            (.cardCookieBackground, .cardCookieAccent),
            (.cardStrawberryBackground, .cardStrawberryAccent),
            (.cardLightBrownBackground, .cardLightBrownAccent)
        ]
        let paletteIndex = index % palettes.count
        return palettes[paletteIndex]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 카드 전체를 Button으로 감싸서 수정 화면으로 이동
            Button(action: {
                onTap?()
            }) {
                // 메인 카드 컨텐츠
                VStack(alignment: .leading, spacing: 12) {
                    // 상단 행: 알람명 (삭제/토글은 overlay로 위에 올려서 정렬)
                    HStack(alignment: .center) {
                        // 알람명
                        Text(alarm.name)
                            .font(.geist(size: 18, weight: .semibold))
                            .foregroundColor(alarm.isEnabled ? .appTextPrimary : .appTextPrimary.opacity(0.6))
                        
                        Spacer()
                        
                        // 삭제 버튼과 토글을 위한 공간 (overlay로 실제 버튼이 올라감)
                        HStack(spacing: 4) {
                            // 삭제 버튼
                            Button(action: {
                                // 햅틱 피드백
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                onDelete()
                            }) {
                                TrashIconView(size: 16, color: .appTextSecondary)
                                    .frame(width: 44, height: 44) // 최소 터치 영역 44x44pt (iOS 가이드라인)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            // 커스텀 토글
                            CustomToggle(
                                isOn: Binding(
                                    get: { alarm.isEnabled },
                                    set: { _ in
                                        onToggle()
                                    }
                                ),
                                accentColor: cardPalette.accent
                            )
                            .frame(width: 56, height: 44) // 최소 터치 영역 44x44pt (iOS 가이드라인)
                            .contentShape(Rectangle())
                        }
                        .opacity(0) // 투명하게 만들어서 공간만 차지
                    }
                    
                    // 중간 행: 시간, AM/PM, 국가 정보, 날짜 (한 줄에)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(alarm.timeOnly)
                            .font(.geist(size: 36, weight: .bold))
                            .foregroundColor(alarm.isEnabled ? .appTextPrimary : .appTextPrimary.opacity(0.6))
                        
                        Text(alarm.amPm)
                            .font(.geist(size: 14, weight: .semibold))
                            .foregroundColor(alarm.isEnabled ? .appTextSecondary : .appTextSecondary.opacity(0.6))
                            .padding(.leading, 1)
                        
                        // 국가 정보
                        HStack(spacing: 8) {
                            Text(alarm.countryFlag)
                                .font(.geist(size: 20, weight: .regular))
                            
                            Text(alarm.countryName)
                                .font(.geist(size: 14, weight: .regular))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.leading, 8)
                        
                        // 날짜 표시 (날짜가 선택된 경우만)
                        if let selectedDate = alarm.selectedDate {
                            HStack(spacing: 8) {
                                Text("•")
                                    .font(.geist(size: 14, weight: .regular))
                                    .foregroundColor(.appTextSecondary)
                                Text(formatDate(selectedDate))
                                    .font(.geist(size: 14, weight: .regular))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding(.leading, 4)
                        }
                        
                        Spacer()
                    }
                    
                    // 하단 행: 요일 버튼 (요일이 선택된 경우)
                    if !alarm.selectedWeekdays.isEmpty && alarm.selectedDate == nil {
                        HStack(spacing: 6) {
                            ForEach(Array(zip(weekdays, weekdayIndices)), id: \.1) { weekday, index in
                                let isSelected = alarm.selectedWeekdays.contains(index)
                                Text(weekday)
                                    .font(.geist(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? cardPalette.accent : Color.clear)
                                    )
                                    .overlay(
                                        // 선택되지 않은 요일: 투명도가 있는 하얀색 동그라미 배경이 글자 위를 덮음
                                        Group {
                                            if !isSelected {
                                                Circle()
                                                    .fill(Color.white.opacity(0.6))
                                            }
                                        }
                                    )
                            }
                            Spacer()
                        }
                        .padding(.top, -4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardPalette.background)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.appCardBorder, lineWidth: 1)
                )
                .overlay(
                    // Vignette 효과 (방사형 그라데이션)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.black.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                )
                .overlay(
                    // 비활성화 시 회색 틴트
                    Group {
                        if !alarm.isEnabled {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.gray.opacity(0.4))
                        }
                    }
                )
                .shadow(color: Color.appShadow.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            // 삭제 버튼과 토글을 overlay로 위에 올려서 탭 우선순위를 높임
            // 타이틀 HStack과 정확히 같은 위치에 배치
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    // 삭제 버튼
                    Button(action: {
                        // 햅틱 피드백
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onDelete()
                    }) {
                        TrashIconView(size: 16, color: .appTextSecondary)
                            .frame(width: 44, height: 44) // 최소 터치 영역 44x44pt (iOS 가이드라인)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // 커스텀 토글
                    CustomToggle(
                        isOn: Binding(
                            get: { alarm.isEnabled },
                            set: { _ in
                                onToggle()
                            }
                        ),
                        accentColor: cardPalette.accent
                    )
                    .frame(width: 56, height: 44) // 최소 터치 영역 44x44pt (iOS 가이드라인)
                    .contentShape(Rectangle())
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
            }
        }
        .clipped()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // 연도 제외, 예: "Jan 15"
        return formatter.string(from: date)
    }
}

// 커스텀 토글 컴포넌트 (작고 완전한 원형)
struct CustomToggle: View {
    @Binding var isOn: Bool
    let accentColor: Color
    
    private let trackWidth: CGFloat = 40
    private let trackHeight: CGFloat = 22
    private let thumbSize: CGFloat = 18
    
    var body: some View {
        Button(action: {
            // 토글 작동
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            // 햅틱 피드백
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // 트랙 (배경)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(isOn ? accentColor : Color.gray.opacity(0.3))
                    .frame(width: trackWidth, height: trackHeight)
                
                // 썸 (완전한 원형)
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AlarmCardView(
        alarm: Alarm(
            name: "Morning Wake Up",
            hour: 7,
            minute: 30,
            timezoneIdentifier: "Asia/Seoul",
            countryName: "South Korea",
            countryFlag: "🇰🇷",
            selectedWeekdays: [2, 3, 4, 5, 6],
            isEnabled: true
        ),
        onToggle: {},
        onDelete: {},
        onTap: nil,
        index: 0
    )
    .padding()
}
