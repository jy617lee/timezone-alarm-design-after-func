/// 무음모드/방해금지모드 체크 및 팝업 표시를 담당하는 ViewModifier
/// 앱이 활성화될 때마다 기기 모드를 확인하고, 필요시 사용자에게 알림을 표시합니다.
import SwiftUI

struct DeviceModeNotificationModifier: ViewModifier {
    @State private var deviceMode: DeviceModeState? = nil
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    let mode = await DeviceModeChecker.shared.checkDeviceMode()
                    deviceMode = mode != .normal ? mode : nil
                }
            }
            .overlay {
                if let mode = deviceMode {
                    SilentModeNotificationView(
                        deviceMode: mode,
                        onDismiss: {
                            deviceMode = nil
                        },
                        onConfirm: {
                            handleConfirmButton(mode: mode)
                            deviceMode = nil
                        }
                    )
                }
            }
    }
    
    private func handleConfirmButton(mode: DeviceModeState) {
        if mode == .doNotDisturb || mode == .both {
            Task {
                let deviceModeChecker = DeviceModeChecker.shared
                let isException = await deviceModeChecker.isDoNotDisturbException()
                
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

