//
//  AlarmFormView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct AlarmFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AlarmViewModel
    
    @State private var alarmName: String = ""
    @State private var selectedHour: Int = 7
    @State private var selectedMinute: Int = 0
    @State private var selectedCountry: Country?
    @State private var selectedDate: Date?
    @State private var selectedWeekdays: Set<Int> = []
    
    let editingAlarm: Alarm?
    
    init(viewModel: AlarmViewModel, editingAlarm: Alarm? = nil) {
        self.viewModel = viewModel
        self.editingAlarm = editingAlarm
        
        if let alarm = editingAlarm {
            _alarmName = State(initialValue: alarm.name)
            _selectedHour = State(initialValue: alarm.hour)
            _selectedMinute = State(initialValue: alarm.minute)
            _selectedDate = State(initialValue: alarm.selectedDate)
            _selectedWeekdays = State(initialValue: alarm.selectedWeekdays)
            
            // 국가 찾기
            if let country = Country.popularCountries.first(where: { $0.timezoneIdentifier == alarm.timezoneIdentifier }) {
                _selectedCountry = State(initialValue: country)
            }
        }
    }
    
    private var isFormValid: Bool {
        !alarmName.isEmpty && selectedCountry != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 알람명
                Section {
                    TextField("Alarm Name", text: $alarmName)
                } header: {
                    Text("Alarm Name")
                }
                
                // 시간 선택 (필수)
                Section {
                    DatePicker("Time", selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = selectedHour
                            components.minute = selectedMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                            selectedHour = components.hour ?? 7
                            selectedMinute = components.minute ?? 0
                        }
                    ), displayedComponents: .hourAndMinute)
                } header: {
                    Text("Time")
                }
                
                // 국가 선택 (필수)
                Section {
                    NavigationLink {
                        CountrySelectionView(selectedCountry: $selectedCountry)
                    } label: {
                        HStack {
                            Text("Country")
                            Spacer()
                            if let country = selectedCountry {
                                HStack(spacing: 8) {
                                    Text(country.flag)
                                    Text(country.name)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Country")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Country")
                }
                
                // 날짜 선택
                Section {
                    DatePicker("Date", selection: Binding(
                        get: {
                            selectedDate ?? Date()
                        },
                        set: { date in
                            selectedDate = date
                            // 날짜 선택 시 반복 초기화
                            selectedWeekdays = []
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                } header: {
                    Text("Date")
                } footer: {
                    Text("Selecting a date will clear repeat settings")
                }
                
                // 반복 선택
                Section {
                    WeekdaySelectionView(selectedWeekdays: $selectedWeekdays, selectedDate: $selectedDate)
                } header: {
                    Text("Repeat")
                } footer: {
                    Text("Selecting repeat days will clear date selection")
                }
            }
            .navigationTitle(editingAlarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveAlarm() {
        guard let country = selectedCountry else { return }
        
        let alarm = Alarm(
            id: editingAlarm?.id ?? UUID(),
            name: alarmName,
            hour: selectedHour,
            minute: selectedMinute,
            timezoneIdentifier: country.timezoneIdentifier,
            countryName: country.name,
            countryFlag: country.flag,
            selectedWeekdays: selectedWeekdays,
            selectedDate: selectedDate,
            isEnabled: true,
            createdAt: editingAlarm?.createdAt ?? Date(),
            sortOrder: editingAlarm?.sortOrder ?? viewModel.alarms.count
        )
        
        if editingAlarm != nil {
            viewModel.updateAlarm(alarm)
        } else {
            viewModel.addAlarm(alarm)
        }
        
        dismiss()
    }
}

// 요일 선택 뷰
struct WeekdaySelectionView: View {
    @Binding var selectedWeekdays: Set<Int>
    @Binding var selectedDate: Date?
    
    private let weekdays = [
        (name: "Sun", index: 1),
        (name: "Mon", index: 2),
        (name: "Tue", index: 3),
        (name: "Wed", index: 4),
        (name: "Thu", index: 5),
        (name: "Fri", index: 6),
        (name: "Sat", index: 7)
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(weekdays, id: \.index) { weekday in
                Button(action: {
                    if selectedWeekdays.contains(weekday.index) {
                        selectedWeekdays.remove(weekday.index)
                    } else {
                        selectedWeekdays.insert(weekday.index)
                        // 반복 선택 시 날짜 초기화
                        selectedDate = nil
                    }
                }) {
                    Text(weekday.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedWeekdays.contains(weekday.index) ? .white : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(selectedWeekdays.contains(weekday.index) ? Color.accentColor : Color(.systemGray5))
                        )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// 국가 선택 뷰
struct CountrySelectionView: View {
    @Binding var selectedCountry: Country?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(Country.popularCountries) { country in
                Button(action: {
                    selectedCountry = country
                    dismiss()
                }) {
                    HStack {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.name)
                            Spacer()
                        if selectedCountry?.id == country.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Country")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AlarmFormView(viewModel: AlarmViewModel())
}

