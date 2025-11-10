//
//  AlarmListView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct AlarmListView: View {
    @Bindable var viewModel: AlarmViewModel
    @Binding var showAlarmForm: Bool
    @Binding var showSettings: Bool
    @Binding var editMode: EditMode
    @State private var editingAlarm: Alarm?
    
    init(viewModel: AlarmViewModel, showAlarmForm: Binding<Bool> = .constant(false), showSettings: Binding<Bool> = .constant(false), editMode: Binding<EditMode> = .constant(.inactive)) {
        self.viewModel = viewModel
        self._showAlarmForm = showAlarmForm
        self._showSettings = showSettings
        self._editMode = editMode
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(viewModel.sortedAlarms.enumerated()), id: \.element.id) { index, alarm in
                    AlarmCardView(
                        alarm: alarm,
                        onToggle: {
                            viewModel.toggleAlarm(alarm)
                        },
                        onDelete: {
                            withAnimation {
                                viewModel.deleteAlarm(alarm)
                            }
                        },
                        onTap: {
                            editingAlarm = alarm
                        },
                        index: index
                    )
                    .onLongPressGesture {
                        // 롱프레스로 드래그 모드 활성화
                        withAnimation {
                            editMode = .active
                        }
                        // 햅틱 피드백
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                }
            }
            .frame(maxWidth: 448)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .environment(\.editMode, $editMode)
        .sheet(item: $editingAlarm) { alarm in
            AlarmFormView(viewModel: viewModel, editingAlarm: alarm)
        }
    }
}

#Preview {
    AlarmListView(viewModel: AlarmViewModel())
}

