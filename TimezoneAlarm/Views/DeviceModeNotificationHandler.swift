//
//  DeviceModeNotificationHandler.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

/// 무음모드/방해금지모드 체크 및 팝업 표시를 담당하는 View
struct DeviceModeNotificationHandler: View {
    @State private var deviceModeToShow: DeviceModeState? = nil
    
    var body: some View {
        Color.clear
            .onAppear {
                // 앱 오픈 시 무음모드/방해금지모드 확인
                Task {
                    await checkAndShowDeviceMode()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // 앱이 활성화될 때 무음모드/방해금지모드 확인
                Task {
                    await checkAndShowDeviceMode()
                }
            }
            .overlay {
                // 무음모드/방해금지모드 안내 팝업
                if let mode = deviceModeToShow {
                    SilentModeNotificationView(
                        deviceMode: mode,
                        onDismiss: {
                            deviceModeToShow = nil
                        },
                        onConfirm: {
                            handleConfirmButton(mode: mode)
                            deviceModeToShow = nil
                        }
                    )
                }
            }
    }
    
    // 기기 모드 확인 및 팝업 표시
    @MainActor
    private func checkAndShowDeviceMode() async {
        let deviceModeChecker = DeviceModeChecker.shared
        let currentMode = await deviceModeChecker.checkDeviceMode()
        
        // normal 모드인 경우 팝업 표시하지 않음
        guard currentMode != .normal else {
            deviceModeToShow = nil
            return
        }
        
        // 방해금지모드인 경우, 예외 앱으로 등록되어 있으면 팝업 표시하지 않음
        if currentMode == .doNotDisturb || currentMode == .both {
            let isException = await deviceModeChecker.isAppInDoNotDisturbException()
            if isException {
                deviceModeToShow = nil
                return
            }
        }
        
        // 조건을 만족하면 해당 모드 표시
        deviceModeToShow = currentMode
    }
    
    // 확인 버튼 처리
    private func handleConfirmButton(mode: DeviceModeState) {
        // 방해금지모드인 경우 설정 페이지로 이동
        if mode == .doNotDisturb || mode == .both {
            Task {
                let deviceModeChecker = DeviceModeChecker.shared
                let isException = await deviceModeChecker.isAppInDoNotDisturbException()
                
                // 예외 앱으로 등록되어 있지 않은 경우에만 설정 페이지로 이동
                if !isException {
                    if let url = deviceModeChecker.getDoNotDisturbSettingsURL() {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

