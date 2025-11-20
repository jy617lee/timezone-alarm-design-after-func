/// 앱 최초 실행 시 한번 팝업을 띄우는 ViewModifier
import SwiftUI

struct DeviceModeNotificationModifier: ViewModifier {
    @State private var showNotification = false
    @AppStorage("hasShownInitialDeviceModeNotification") private var hasShownInitialNotification = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasShownInitialNotification {
                    showNotification = true
                    hasShownInitialNotification = true
                }
            }
            .overlay {
                if showNotification {
                    SilentModeNotificationView(
                        deviceMode: .doNotDisturb,
                        onDismiss: {
                            showNotification = false
                        },
                        onConfirm: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                Task {
                                    await UIApplication.shared.open(url)
                                }
                            }
                            showNotification = false
                        }
                    )
                }
            }
    }
}

extension View {
    func deviceModeNotification() -> some View {
        modifier(DeviceModeNotificationModifier())
    }
}

