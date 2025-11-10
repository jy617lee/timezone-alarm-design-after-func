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
    private var cardPalette: (background: Color, accent: Color) {
        let palettes: [(background: Color, accent: Color)] = [
            (.cardStrawberryBackground, .cardStrawberryAccent),
            (.cardPistachioBackground, .cardPistachioAccent),
            (.cardLemonBackground, .cardLemonAccent),
            (.cardBerryBackground, .cardBerryAccent),
            (.cardCookieBackground, .cardCookieAccent),
            (.cardOrangeBackground, .cardOrangeAccent),
            (.cardHotPinkBackground, .cardHotPinkAccent),
            (.cardLightBrownBackground, .cardLightBrownAccent)
        ]
        let index = abs(alarm.id.hashValue) % palettes.count
        return palettes[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 메인 카드 컨텐츠
            VStack(alignment: .leading, spacing: 12) {
                // 상단: 알람명과 삭제 아이콘
                HStack {
                    Text(alarm.name)
                        .font(.geist(size: 17, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        // 햅틱 피드백
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.geist(size: 17, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                
                // 시간과 토글
                HStack {
                    Text(alarm.formattedTime)
                        .font(.geist(size: 32, weight: .light))
                        .foregroundColor(.appTextPrimary)
                    
                    Spacer()
                    
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
                
                // 국가 정보
                HStack(spacing: 8) {
                    Text(alarm.countryFlag)
                        .font(.geist(size: 20, weight: .regular))
                    
                    Text(alarm.countryName)
                        .font(.geist(size: 15, weight: .regular))
                        .foregroundColor(.appTextSecondary)
                }
                
                // 날짜 또는 요일 표시
                if let selectedDate = alarm.selectedDate {
                    // 날짜가 선택된 경우
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.geist(size: 12, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                        Text(formatDate(selectedDate))
                            .font(.geist(size: 15, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                    }
                } else if !alarm.selectedWeekdays.isEmpty {
                    // 요일이 선택된 경우
                    HStack(spacing: 8) {
                        ForEach(Array(zip(weekdays, weekdayIndices)), id: \.1) { weekday, index in
                            Text(weekday)
                                .font(.geist(size: 12, weight: .semibold))
                                .foregroundColor(alarm.selectedWeekdays.contains(index) ? .appTextOnPrimary : .appTextSecondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(alarm.selectedWeekdays.contains(index) ? cardPalette.accent : Color.clear)
                                )
                        }
                    }
                } else {
                    // 날짜도 요일도 선택되지 않은 경우
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.geist(size: 12, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                        Text(NSLocalizedString("alarm_card.once", comment: "Once"))
                            .font(.geist(size: 15, weight: .regular))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardPalette.background)
            .cornerRadius(16)
            .shadow(color: Color.appShadow, radius: 5, x: 0, y: 2)
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

