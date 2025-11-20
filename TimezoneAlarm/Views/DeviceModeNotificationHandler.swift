/// 무음모드/방해금지모드 체크 및 팝업 표시를 담당하는 ViewModifier
/// 앱이 활성화될 때마다 기기 모드를 확인하고, 필요시 사용자에게 알림을 표시합니다.
import SwiftUI

struct DeviceModeNotificationModifier: ViewModifier {
    @State private var deviceModeToShow: DeviceModeState? = nil
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    deviceModeToShow = await shouldShowDeviceModeNotification()
                }
            }
            .overlay {
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
    
    @MainActor
    private func shouldShowDeviceModeNotification() async -> DeviceModeState? {
        let deviceModeChecker = DeviceModeChecker.shared
        let currentMode = await deviceModeChecker.checkDeviceMode()
        
        guard currentMode != .normal else {
            return nil
        }
        
        if currentMode == .doNotDisturb || currentMode == .both {
            let isException = await deviceModeChecker.isAppInDoNotDisturbException()
            if isException {
                return nil
            }
        }
        
        return currentMode
    }
    
    private func handleConfirmButton(mode: DeviceModeState) {
        if mode == .doNotDisturb || mode == .both {
            Task {
                let deviceModeChecker = DeviceModeChecker.shared
                let isException = await deviceModeChecker.isAppInDoNotDisturbException()
                
                if !isException {
                    if let url = deviceModeChecker.getDoNotDisturbSettingsURL() {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}

extension View {
    func deviceModeNotification() -> some View {
        modifier(DeviceModeNotificationModifier())
    }
}

