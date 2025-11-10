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
    @State private var editMode: EditMode = .inactive
    @State private var editingAlarm: Alarm?
    
    init(viewModel: AlarmViewModel, showAlarmForm: Binding<Bool> = .constant(false)) {
        self.viewModel = viewModel
        self._showAlarmForm = showAlarmForm
    }
    
    var body: some View {
        List {
            ForEach(viewModel.sortedAlarms) { alarm in
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
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
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
            .onMove(perform: viewModel.moveAlarm)
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if editMode == .active {
                    Button("Done") {
                        withAnimation {
                            editMode = .inactive
                        }
                    }
                }
            }
        }
        .sheet(item: $editingAlarm) { alarm in
            AlarmFormView(viewModel: viewModel, editingAlarm: alarm)
        }
    }
}

#Preview {
    AlarmListView(viewModel: AlarmViewModel())
}

