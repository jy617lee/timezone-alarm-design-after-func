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
    
    var body: some View {
        HStack(spacing: 0) {
            // 메인 카드 컨텐츠
            VStack(alignment: .leading, spacing: 12) {
                // 상단: 알람명과 삭제 아이콘
                HStack {
                    Text(alarm.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        // 햅틱 피드백
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                
                // 시간과 토글
                HStack {
                    Text(alarm.formattedTime)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.primary)
                    
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
                }
                
                // 국가 정보
                HStack(spacing: 8) {
                    Text(alarm.countryFlag)
                        .font(.title3)
                    
                    Text(alarm.countryName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 날짜 또는 요일 표시
                if let selectedDate = alarm.selectedDate {
                    // 날짜가 선택된 경우
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(selectedDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if !alarm.selectedWeekdays.isEmpty {
                    // 요일이 선택된 경우
                    HStack(spacing: 8) {
                        ForEach(Array(zip(weekdays, weekdayIndices)), id: \.1) { weekday, index in
                            Text(weekday)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(alarm.selectedWeekdays.contains(index) ? .white : .secondary)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(alarm.selectedWeekdays.contains(index) ? Color.accentColor : Color.clear)
                                )
                        }
                    }
                } else {
                    // 날짜도 요일도 선택되지 않은 경우
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Once")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .frame(width: abs(dragOffset))
                            .frame(height: cardGeometry.size.height)
                            .background(
                                Color.red.opacity(0.3)
                            )
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

