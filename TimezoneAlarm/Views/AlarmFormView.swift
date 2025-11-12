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
    @State private var selectedCity: City?
    @State private var selectedDate: Date?
    @State private var selectedWeekdays: Set<Int> = []
    @State private var datePickerValue: Date = Date()
    @State private var tempTime: Date = Date()
    @State private var showTimePicker: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    let editingAlarm: Alarm?
    
    init(viewModel: AlarmViewModel, editingAlarm: Alarm? = nil) {
        self.viewModel = viewModel
        self.editingAlarm = editingAlarm
        
        // 모든 State 변수를 기본값으로 먼저 초기화
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        _alarmName = State(initialValue: "")
        _selectedHour = State(initialValue: 7)
        _selectedMinute = State(initialValue: 0)
        _selectedCity = State(initialValue: nil)
        _selectedDate = State(initialValue: nil)
        _selectedWeekdays = State(initialValue: [])
        _datePickerValue = State(initialValue: tomorrow)
        _tempTime = State(initialValue: Date())
        _showTimePicker = State(initialValue: false)
        _showDatePicker = State(initialValue: false)
        _showToast = State(initialValue: false)
        _toastMessage = State(initialValue: "")
        
        // editingAlarm이 있으면 해당 값으로 덮어쓰기
        if let alarm = editingAlarm {
            _alarmName = State(initialValue: alarm.name)
            _selectedHour = State(initialValue: alarm.hour)
            _selectedMinute = State(initialValue: alarm.minute)
            _selectedDate = State(initialValue: alarm.selectedDate)
            _selectedWeekdays = State(initialValue: alarm.selectedWeekdays)
            
            if let date = alarm.selectedDate {
                _datePickerValue = State(initialValue: date)
            }
            
            // 도시 찾기
            if let city = City.popularCities.first(where: { $0.timezoneIdentifier == alarm.timezoneIdentifier }) {
                _selectedCity = State(initialValue: city)
            }
        } else {
            // 새 알람 생성 시 기본 도시 로드
            if let timezoneId = UserDefaults.standard.string(forKey: "defaultTimezoneId"),
               let city = City.popularCities.first(where: { $0.timezoneIdentifier == timezoneId }) {
                _selectedCity = State(initialValue: city)
            }
            // 새 알람 생성 시 날짜 초기값을 내일 날짜로 설정
            _selectedDate = State(initialValue: tomorrow)
        }
    }
    
    private var isFormValid: Bool {
        !alarmName.isEmpty && 
        selectedCity != nil &&
        (!selectedWeekdays.isEmpty || selectedDate != nil)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 그라데이션 백그라운드
                LinearGradient(
                    colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 28) {
                        // 알람명 (필수)
                        FormSection(
                            title: NSLocalizedString("alarm_form.alarm_name", comment: "Alarm name header"),
                            isRequired: true
                        ) {
                            TextField(NSLocalizedString("alarm_form.alarm_name", comment: "Alarm name placeholder"), text: $alarmName)
                                .font(.geist(size: 16, weight: .light))
                                .foregroundColor(.appTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
            
                        // 시간 선택 (필수)
                        FormSection(
                            title: NSLocalizedString("alarm_form.time", comment: "Time header"),
                            isRequired: true
                        ) {
                            Button(action: {
                                // 현재 선택된 시간으로 tempTime 초기화
                                var components = DateComponents()
                                components.hour = selectedHour
                                components.minute = selectedMinute
                                tempTime = Calendar.current.date(from: components) ?? Date()
                                showTimePicker = true
                            }) {
                                Text(String(format: "%d:%02d %@", 
                                              selectedHour > 12 ? selectedHour - 12 : (selectedHour == 0 ? 12 : selectedHour),
                                              selectedMinute,
                                              selectedHour >= 12 ? "PM" : "AM"))
                                    .font(.geist(size: 16, weight: .light))
                                    .foregroundColor(.appTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 도시 선택 (필수)
                        FormSection(
                            title: NSLocalizedString("alarm_form.city", comment: "City header"),
                            isRequired: true
                        ) {
                            NavigationLink {
                                CitySelectionView(selectedCity: $selectedCity)
                            } label: {
                                HStack {
                                    if let city = selectedCity {
                                        Text(city.countryFlag)
                                            .font(.geist(size: 24, weight: .regular))
                                        Text(city.name)
                                            .font(.geist(size: 16, weight: .light))
                                            .foregroundColor(.appTextPrimary)
                                    } else {
                                        Text(NSLocalizedString("alarm_form.select_city", comment: "Select city"))
                                            .font(.geist(size: 16, weight: .light))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.geist(size: 14, weight: .medium))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                
                        // 날짜 선택
                        FormSection(
                            title: NSLocalizedString("alarm_form.date", comment: "Date header")
                        ) {
                            HStack {
                                if let date = selectedDate {
                                    Button(action: {
                                        showDatePicker = true
                                    }) {
                                        Text(formatDate(date))
                                            .font(.geist(size: 16, weight: .light))
                                            .foregroundColor(.appTextPrimary)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button(action: {
                                        showDatePicker = true
                                    }) {
                                        Text(NSLocalizedString("alarm_form.date_not_selected", comment: "Not selected"))
                                            .font(.geist(size: 16, weight: .light))
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.geist(size: 14, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // 반복 선택
                        FormSection(
                            title: NSLocalizedString("alarm_form.repeat", comment: "Repeat"),
                            hideBackground: true
                        ) {
                            WeekdaySelectionView(
                                selectedWeekdays: $selectedWeekdays,
                                selectedDate: $selectedDate
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(editingAlarm == nil ? NSLocalizedString("alarm_form.title.new", comment: "New alarm") : NSLocalizedString("alarm_form.title.edit", comment: "Edit alarm"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(Color.appHeaderBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .onAppear {
                // NavigationBar 버튼 배경 완전히 제거
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = UIColor.clear
                appearance.shadowColor = .clear
                
                // 버튼 배경 완전히 제거
                let buttonAppearance = UIBarButtonItemAppearance()
                buttonAppearance.normal.backgroundImage = UIImage()
                buttonAppearance.highlighted.backgroundImage = UIImage()
                buttonAppearance.disabled.backgroundImage = UIImage()
                buttonAppearance.normal.titleTextAttributes = [:]
                buttonAppearance.highlighted.titleTextAttributes = [:]
                appearance.buttonAppearance = buttonAppearance
                appearance.doneButtonAppearance = buttonAppearance
                appearance.backButtonAppearance = buttonAppearance
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                // 버튼 배경 완전 제거를 위한 추가 설정
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        @MainActor
                        func removeButtonBackgrounds(from view: UIView) {
                            if let button = view as? UIButton {
                                button.backgroundColor = .clear
                                button.layer.backgroundColor = UIColor.clear.cgColor
                                button.setBackgroundImage(nil, for: .normal)
                                button.setBackgroundImage(nil, for: .highlighted)
                                button.setBackgroundImage(nil, for: .disabled)
                                button.setBackgroundImage(nil, for: .selected)
                                button.tintColor = .brown
                                if #available(iOS 15.0, *) {
                                    var config = button.configuration ?? UIButton.Configuration.plain()
                                    config.background.backgroundColor = .clear
                                    config.background.cornerRadius = 0
                                    config.baseForegroundColor = .brown
                                    button.configuration = config
                                }
                            }
                            for subview in view.subviews {
                                removeButtonBackgrounds(from: subview)
                            }
                        }
                        for subview in window.subviews {
                            removeButtonBackgrounds(from: subview)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(editingAlarm == nil ? NSLocalizedString("alarm_form.title.new", comment: "New alarm") : NSLocalizedString("alarm_form.title.edit", comment: "Edit alarm"))
                        .font(.geist(size: 20, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .renderingMode(.template)
                            .foregroundColor(.brown)
                    }
                    .buttonStyle(.plain)
                    .tint(.brown)
                    .accentColor(.brown)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveAlarm()
                    }) {
                        Text(NSLocalizedString("button.save", comment: "Save button"))
                            .font(.geist(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isFormValid ? Color.appPrimary : Color.appPrimary.opacity(0.5))
                            .cornerRadius(20)
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.plain)
                    .background(Color.clear)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    ZStack {
                        // 그라데이션 백그라운드
                        LinearGradient(
                            colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        VStack {
                            DatePicker(NSLocalizedString("alarm_form.date", comment: "Date"), selection: $datePickerValue, displayedComponents: .date)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            
                            Spacer()
                        }
                    }
                    .navigationTitle(NSLocalizedString("alarm_form.select_date", comment: "Select date"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(NSLocalizedString("alarm_form.select_date", comment: "Select date"))
                                .font(.geist(size: 18, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(NSLocalizedString("button.cancel", comment: "Cancel button")) {
                                showDatePicker = false
                            }
                            .font(.geist(size: 16, weight: .regular))
                            .foregroundColor(.appTextPrimary)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("button.done", comment: "Done button")) {
                                // 선택한 날짜와 시간을 조합하여 알람 시간 생성
                                let calendar = Calendar.current
                                
                                // 선택한 날짜의 시간을 현재 선택된 시간으로 설정
                                var dateComponents = calendar.dateComponents([.year, .month, .day], from: datePickerValue)
                                dateComponents.hour = selectedHour
                                dateComponents.minute = selectedMinute
                                
                                guard let alarmDateTime = calendar.date(from: dateComponents) else {
                                    showDatePicker = false
                                    return
                                }
                                
                                // 현재 시간보다 이전인지 확인
                                if alarmDateTime <= Date() {
                                    // 토스트 메시지 표시 (사용자 기기 언어로)
                                    toastMessage = NSLocalizedString("past_time_selection_error", comment: "Past time selection error message")
                                    showToast = true
                                    // 선택 취소
                                    showDatePicker = false
                                    return
                                }
                                
                                // 유효한 날짜이면 저장
                                selectedDate = datePickerValue
                                selectedWeekdays = []
                                showDatePicker = false
                            }
                            .font(.geist(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appPrimary)
                            .cornerRadius(20)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .overlay(
                // 토스트 메시지
                ToastView(message: toastMessage, isShowing: $showToast)
                    .animation(.easeInOut, value: showToast)
            )
            .sheet(isPresented: $showTimePicker) {
                NavigationView {
                    ZStack {
                        // 그라데이션 백그라운드
                        LinearGradient(
                            colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        VStack {
                            DatePicker(NSLocalizedString("alarm_form.time", comment: "Time"), selection: $tempTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                            
                            Spacer()
                        }
                    }
                    .navigationTitle(NSLocalizedString("alarm_form.select_time", comment: "Select time"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(NSLocalizedString("alarm_form.select_time", comment: "Select time"))
                                .font(.geist(size: 18, weight: .semibold))
                                .foregroundColor(.appTextPrimary)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(NSLocalizedString("button.cancel", comment: "Cancel button")) {
                                showTimePicker = false
                            }
                            .font(.geist(size: 16, weight: .regular))
                            .foregroundColor(.appTextPrimary)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(NSLocalizedString("button.done", comment: "Done button")) {
                                // 선택한 날짜와 시간을 조합하여 알람 시간 생성
                                let calendar = Calendar.current
                                let selectedDateForValidation = selectedDate ?? Date() // 날짜가 없으면 오늘
                                
                                // 선택한 날짜의 시간을 선택한 시간으로 설정
                                var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDateForValidation)
                                let timeComponents = calendar.dateComponents([.hour, .minute], from: tempTime)
                                dateComponents.hour = timeComponents.hour
                                dateComponents.minute = timeComponents.minute
                                
                                guard let alarmDateTime = calendar.date(from: dateComponents) else {
                                    showTimePicker = false
                                    return
                                }
                                
                                // 현재 시간보다 이전인지 확인
                                if alarmDateTime <= Date() {
                                    // 토스트 메시지 표시 (사용자 기기 언어로)
                                    toastMessage = NSLocalizedString("past_time_selection_error", comment: "Past time selection error message")
                                    showToast = true
                                    // 선택 취소
                                    showTimePicker = false
                                    return
                                }
                                
                                // 유효한 시간이면 저장
                                let components = calendar.dateComponents([.hour, .minute], from: tempTime)
                                selectedHour = components.hour ?? 7
                                selectedMinute = components.minute ?? 0
                                showTimePicker = false
                            }
                            .font(.geist(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appPrimary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    private func saveAlarm() {
        guard let city = selectedCity else { return }
        
        let alarm = Alarm(
            id: editingAlarm?.id ?? UUID(),
            name: alarmName,
            hour: selectedHour,
            minute: selectedMinute,
            timezoneIdentifier: city.timezoneIdentifier,
            countryName: city.countryName,
            countryFlag: city.countryFlag,
            selectedWeekdays: selectedWeekdays,
            selectedDate: selectedDate,
            isEnabled: editingAlarm?.isEnabled ?? true, // 수정 시 기존 상태 유지, 새 알람은 기본값 true
            createdAt: editingAlarm?.createdAt ?? Date(),
            sortOrder: editingAlarm?.sortOrder ?? viewModel.alarms.count
        )
        
            if editingAlarm != nil {
                viewModel.updateAlarm(alarm)
            } else {
                viewModel.addAlarm(alarm)
            }
            
            // addAlarm/updateAlarm에서 이미 스케줄링 처리됨
            debugLog("📝 알람 저장 완료: \(alarm.name)")
            debugLog("   - 날짜: \(alarm.selectedDate?.description ?? "nil")")
            debugLog("   - 요일: \(alarm.selectedWeekdays)")
            
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
        Weekday(id: 1, name: NSLocalizedString("weekday.sun", comment: "Sunday")),
        Weekday(id: 2, name: NSLocalizedString("weekday.mon", comment: "Monday")),
        Weekday(id: 3, name: NSLocalizedString("weekday.tue", comment: "Tuesday")),
        Weekday(id: 4, name: NSLocalizedString("weekday.wed", comment: "Wednesday")),
        Weekday(id: 5, name: NSLocalizedString("weekday.thu", comment: "Thursday")),
        Weekday(id: 6, name: NSLocalizedString("weekday.fri", comment: "Friday")),
        Weekday(id: 7, name: NSLocalizedString("weekday.sat", comment: "Saturday"))
    ]
    
    var body: some View {
        HStack(spacing: 6) {
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
                Text(String(weekday.name.prefix(1)))
                    .font(.geist(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.cardHotPinkAccent : Color.clear)
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
            // 2. 버튼마다 id 넣기 (고정된 id 사용)
            .id("weekday-\(weekday.id)")
            .buttonStyle(.plain)  // 버튼 스타일을 plain으로 설정하여 터치 영역 문제 방지
            .contentShape(Circle())  // 터치 영역을 Circle로 명확히 지정 (Button에 적용)
        }
    }
}

// 국가 선택 뷰
struct CitySelectionView: View {
    @Binding var selectedCity: City?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    private var filteredCities: [City] {
        if searchText.isEmpty {
            return City.popularCities
        } else {
            return City.popularCities.filter { city in
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.countryName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 그라데이션 백그라운드
            LinearGradient(
                colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredCities) { city in
                        Button(action: {
                            selectedCity = city
                            dismiss()
                        }) {
                            HStack {
                                Text(city.countryFlag)
                                    .font(.geist(size: 22, weight: .regular))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name)
                                        .font(.geist(size: 16, weight: .regular))
                                        .foregroundColor(.appTextPrimary)
                                    Text(city.countryName)
                                        .font(.geist(size: 13, weight: .regular))
                                        .foregroundColor(.appTextSecondary)
                                }
                                Spacer()
                                if selectedCity?.id == city.id {
                                    Image(systemName: "checkmark")
                                        .font(.geist(size: 16, weight: .semibold))
                                        .foregroundColor(.appPrimary)
                                }
                            }
                            .padding(16)
                            .background(Color.appCardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appCardBorder, lineWidth: 1)
                            )
                            .shadow(color: Color.appShadow.opacity(0.2), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
        .searchable(text: $searchText, prompt: NSLocalizedString("alarm_form.search_cities", comment: "Search cities"))
        .navigationTitle(NSLocalizedString("alarm_form.select_city", comment: "Select city"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(NSLocalizedString("alarm_form.select_city", comment: "Select city"))
                    .font(.geist(size: 18, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
            }
        }
    }
}

// Form Section 컴포넌트
struct FormSection<Content: View>: View {
    let title: String
    let isRequired: Bool
    let hideBackground: Bool
    let content: Content
    
    init(title: String, isRequired: Bool = false, hideBackground: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.hideBackground = hideBackground
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !title.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(title)
                        .font(.geist(size: 16, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    
                    if isRequired {
                        Text("*")
                            .font(.geist(size: 16, weight: .semibold))
                            .foregroundColor(.appPrimary)
                            .baselineOffset(0)
                    }
                }
            }
            
            VStack(spacing: 0) {
                content
            }
            .padding(hideBackground ? 0 : 16)
            .background(hideBackground ? Color.clear : Color.appCardBackground)
            .cornerRadius(hideBackground ? 0 : 16)
            .overlay(
                Group {
                    if !hideBackground {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appCardBorder, lineWidth: 1)
                    }
                }
            )
            .shadow(color: hideBackground ? .clear : Color.appShadow.opacity(0.2), radius: hideBackground ? 0 : 8, x: 0, y: hideBackground ? 0 : 2)
        }
    }
}

// 토스트 메시지 뷰
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing && !message.isEmpty {
                Text(message)
                    .font(.geist(size: 15, weight: .regular))
                    .foregroundColor(.appTextOnPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appAlertBackground.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        // 2초 후 자동으로 사라짐
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    AlarmFormView(viewModel: AlarmViewModel())
}

