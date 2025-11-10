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
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let weekdayIndices = [1, 2, 3, 4, 5, 6, 7] // Sunday=1, Monday=2, ..., Saturday=7
    
    // 카드 색상 팔레트 선택 (알람 ID 기반)
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
        let index = abs(alarm.id.hashValue) % palettes.count
        return palettes[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 메인 카드 컨텐츠
            VStack(alignment: .leading, spacing: 16) {
                // 상단 행: 알람명, 삭제 버튼, 토글
                HStack {
                    Text(alarm.name)
                        .font(.geist(size: 18, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    
                    Spacer()
                    
                    // 삭제 버튼
                    Button(action: {
                        // 햅틱 피드백
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onDelete()
                    }) {
                        // 커스텀 휴지통 아이콘 (세로줄 2개, 두꺼운 선)
                        ZStack {
                            // 휴지통 몸체
                            Path { path in
                                // 왼쪽 벽
                                path.move(to: CGPoint(x: 4, y: 6))
                                path.addLine(to: CGPoint(x: 4, y: 18))
                                // 바닥
                                path.addLine(to: CGPoint(x: 12, y: 18))
                                // 오른쪽 벽
                                path.addLine(to: CGPoint(x: 12, y: 6))
                                // 뚜껑 왼쪽
                                path.move(to: CGPoint(x: 2, y: 6))
                                path.addLine(to: CGPoint(x: 4, y: 6))
                                // 뚜껑 오른쪽
                                path.move(to: CGPoint(x: 12, y: 6))
                                path.addLine(to: CGPoint(x: 14, y: 6))
                                // 뚜껑 손잡이
                                path.move(to: CGPoint(x: 6, y: 4))
                                path.addLine(to: CGPoint(x: 10, y: 4))
                            }
                            .stroke(Color.appTextSecondary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            
                            // 세로줄 2개
                            Path { path in
                                // 왼쪽 세로줄
                                path.move(to: CGPoint(x: 6.5, y: 8))
                                path.addLine(to: CGPoint(x: 6.5, y: 16))
                                // 오른쪽 세로줄
                                path.move(to: CGPoint(x: 9.5, y: 8))
                                path.addLine(to: CGPoint(x: 9.5, y: 16))
                            }
                            .stroke(Color.appTextSecondary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }
                        .frame(width: 16, height: 20)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    
                    Toggle("", isOn: Binding(
                        get: { alarm.isEnabled },
                        set: { _ in
                            // 햅틱 피드백
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onToggle()
                        }
                    ))
                    .labelsHidden()
                    .tint(cardPalette.accent)
                }
                
                // 중간 행: 시간, AM/PM, 국가 정보, 날짜/요일 (한 줄에)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(alarm.timeOnly)
                        .font(.geist(size: 36, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                    
                    Text(alarm.amPm)
                        .font(.geist(size: 18, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                        .padding(.leading, 4)
                    
                    // 국가 정보
                    HStack(spacing: 8) {
                        Text(alarm.countryFlag)
                            .font(.geist(size: 20, weight: .regular))
                        
                        Text(alarm.countryName)
                            .font(.geist(size: 14, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.leading, 8)
                    
                    // 날짜 또는 요일 표시
                    if let selectedDate = alarm.selectedDate {
                        // 날짜가 선택된 경우
                        HStack(spacing: 8) {
                            Text("•")
                                .font(.geist(size: 14, weight: .regular))
                                .foregroundColor(.appTextSecondary)
                            Text(formatDate(selectedDate))
                                .font(.geist(size: 14, weight: .regular))
                                .foregroundColor(.appTextSecondary)
                        }
                        .padding(.leading, 4)
                    } else if !alarm.selectedWeekdays.isEmpty {
                        // 요일이 선택된 경우
                        HStack(spacing: 6) {
                            ForEach(Array(zip(weekdays, weekdayIndices)), id: \.1) { weekday, index in
                                let isSelected = alarm.selectedWeekdays.contains(index)
                                Text(weekday)
                                    .font(.geist(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? .appTextOnPrimary : .appTextSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? cardPalette.accent : Color.appMutedBackground.opacity(0.5))
                                    )
                            }
                        }
                        .padding(.leading, 4)
                    }
                    
                    Spacer()
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
            .shadow(color: Color.appShadow.opacity(0.3), radius: 8, x: 0, y: 4)
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // 왼쪽으로만 스와이프 가능 (제한 없이 끝까지)
                        if value.translation.width < 0 {
                            dragOffset = value.translation.width
                            isDragging = true
                        } else if value.translation.width > 0 && dragOffset < 0 {
                            // 왼쪽으로 스와이프한 상태에서 오른쪽으로 되돌릴 때
                            // 즉시 원래 위치로 복귀
                            withAnimation(.spring()) {
                                dragOffset = 0
                                isDragging = false
                            }
                        }
                        // 오른쪽으로 스와이프할 때는 아무 동작 안함 (dragOffset이 0인 상태에서)
                    }
                    .onEnded { value in
                        // 왼쪽으로 스와이프한 경우에만 처리
                        if value.translation.width < 0 {
                            if value.translation.width < -50 {
                                // 삭제 트리거
                                withAnimation {
                                    onDelete()
                                }
                            } else {
                                // 원래 위치로 복귀
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                    isDragging = false
                                }
                            }
                        } else {
                            // 오른쪽으로 스와이프한 경우 아무 동작 안함
                            // dragOffset은 이미 0이므로 그대로 유지
                        }
                    }
            )
            .onTapGesture {
                // 스와이프 중이 아닐 때만 탭 처리
                if !isDragging && dragOffset == 0 {
                    onTap?()
                }
            }
            .background(
                // 오른쪽 삭제 아이콘 영역 (왼쪽 스와이프 시 표시, 동적으로 늘어남)
                GeometryReader { cardGeometry in
                    if dragOffset < 0 {
                        Button(action: {
                            withAnimation {
                                onDelete()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                    .font(.geist(size: 22, weight: .regular))
                                    .foregroundColor(.appTextOnPrimary)
                                Spacer()
                            }
                            .frame(width: abs(dragOffset))
                            .frame(height: cardGeometry.size.height)
                            .background(Color.appDeleteBackground)
                        }
                        .offset(x: cardGeometry.size.width + dragOffset)
                        .transition(.opacity)
                    }
                }
            )
        }
        .clipped()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
        onTap: nil
    )
    .padding()
}

