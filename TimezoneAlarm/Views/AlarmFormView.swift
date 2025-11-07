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
    @State private var datePickerValue: Date = Date()
    @State private var tempTime: Date = Date()
    @State private var showTimePicker: Bool = false
    @State private var showDatePicker: Bool = false
    
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
            
            if let date = alarm.selectedDate {
                _datePickerValue = State(initialValue: date)
            }
            
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
                    Button(action: {
                        // 현재 선택된 시간으로 tempTime 초기화
                        var components = DateComponents()
                        components.hour = selectedHour
                        components.minute = selectedMinute
                        tempTime = Calendar.current.date(from: components) ?? Date()
                        showTimePicker = true
                    }) {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(String(format: "%d:%02d %@", 
                                      selectedHour > 12 ? selectedHour - 12 : (selectedHour == 0 ? 12 : selectedHour),
                                      selectedMinute,
                                      selectedHour >= 12 ? "PM" : "AM"))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Time")
                }
                .sheet(isPresented: $showTimePicker) {
                    NavigationView {
                        VStack {
                            DatePicker("Time", selection: $tempTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            
                            Spacer()
                        }
                        .navigationTitle("Select Time")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    showTimePicker = false
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: tempTime)
                                    selectedHour = components.hour ?? 7
                                    selectedMinute = components.minute ?? 0
                                    showTimePicker = false
                                }
                            }
                        }
                    }
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
                    if selectedDate != nil {
                        HStack {
                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text("Date")
                                    Spacer()
                                    if let date = selectedDate {
                                        Text(formatDate(date))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                selectedDate = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text("Date")
                                Spacer()
                                Text("Not selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Date")
                } footer: {
                    Text("Selecting a date will clear repeat settings")
                }
                
                // 반복 선택
                Section {
                    WeekdaySelectionView(
                        selectedWeekdays: $selectedWeekdays,
                        selectedDate: $selectedDate
                    )
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
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    VStack {
                        DatePicker("Date", selection: $datePickerValue, displayedComponents: .date)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                        
                        Spacer()
                    }
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedDate = datePickerValue
                                selectedWeekdays = []
                                showDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
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
        
        // 테스트용: 5초 후 알람 실행
        viewModel.scheduleTestAlarm(alarm)
        
        dismiss()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// 요일 선택 뷰
struct WeekdaySelectionView: View {
    @Binding var selectedWeekdays: Set<Int>
    @Binding var selectedDate: Date?
    
    // 1. 각 요일별 id 매핑
    struct Weekday: Identifiable {
        let id: Int  // 1=일, 2=월, 3=화, 4=수, 5=목, 6=금, 7=토
        let name: String
    }
    
    private let weekdays = [
        Weekday(id: 1, name: "Sun"),
        Weekday(id: 2, name: "Mon"),
        Weekday(id: 3, name: "Tue"),
        Weekday(id: 4, name: "Wed"),
        Weekday(id: 5, name: "Thu"),
        Weekday(id: 6, name: "Fri"),
        Weekday(id: 7, name: "Sat")
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(weekdays, id: \.id) { weekday in
                WeekdayButton(
                    weekday: weekday,
                    selectedWeekdays: $selectedWeekdays,
                    selectedDate: $selectedDate
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // 개별 요일 버튼
    struct WeekdayButton: View {
        let weekday: Weekday
        @Binding var selectedWeekdays: Set<Int>
        @Binding var selectedDate: Date?
        
        // 5. 함수 내에서는 현재 선택된 요일에 눌린 버튼의 id가 있다면 없애주고, 없다면 set에 더해주는 동작
        // 버튼 내부에서 직접 처리하여 바인딩 업데이트가 제대로 전파되도록 함
        private func toggleWeekday() {
            let weekdayId = weekday.id  // 클로저 캡처 문제 방지를 위해 로컬 변수로 저장
            var newSet = Set(selectedWeekdays)
            if newSet.contains(weekdayId) {
                newSet.remove(weekdayId)
            } else {
                newSet.insert(weekdayId)
            }
            
            // Set 전체를 보고 결정: 요일이 하나라도 선택되어 있으면 날짜 초기화
            if !newSet.isEmpty {
                selectedDate = nil
            }
            
            // Set을 새로 할당하여 SwiftUI가 변경을 감지하도록 함
            selectedWeekdays = newSet
        }
        
        var body: some View {
            // 6. 뷰에서는 전역상태에서 선택된 요일의 set을 보고 회색/파란색 노출 결정
            // body 내부에서 직접 selectedWeekdays.contains를 사용하여 SwiftUI가 의존성을 추적할 수 있도록 함
            let weekdayId = weekday.id  // 클로저 캡처 문제 방지를 위해 로컬 변수로 저장
            let isSelected = selectedWeekdays.contains(weekdayId)
            
            return Button(action: {
                // 4. 버튼이 눌릴 때마다 눌린 버튼의 id를 인자로 하는 함수 호출
                toggleWeekday()
            }) {
                Text(weekday.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                    )
            }
            // 2. 버튼마다 id 넣기 (고정된 id 사용)
            .id("weekday-\(weekday.id)")
            .buttonStyle(.plain)  // 버튼 스타일을 plain으로 설정하여 터치 영역 문제 방지
            .contentShape(Circle())  // 터치 영역을 Circle로 명확히 지정 (Button에 적용)
        }
    }
}

// 국가 선택 뷰
struct CountrySelectionView: View {
    @Binding var selectedCountry: Country?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return Country.popularCountries
        } else {
            return Country.popularCountries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredCountries) { country in
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
        .searchable(text: $searchText, prompt: "Search countries")
        .navigationTitle("Select Country")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AlarmFormView(viewModel: AlarmViewModel())
}

