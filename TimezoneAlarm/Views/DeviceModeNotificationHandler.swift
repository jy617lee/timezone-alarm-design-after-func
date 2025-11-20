/// 앱 최초 실행 시 한번 팝업을 띄우는 ViewModifier
import SwiftUI

struct DeviceModeNotificationModifier: ViewModifier {
    @State private var showNotification = false
    @AppStorage("hasShownInitialDeviceModeNotification") private var hasShownInitialNotification = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 약간의 지연을 두어 뷰가 완전히 렌더링된 후 팝업 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !hasShownInitialNotification {
                        showNotification = true
                        hasShownInitialNotification = true
                    }
                }
            }
            .overlay {
                if showNotification {
                    SilentModeNotificationView(
                        onDismiss: {
                            showNotification = false
                        },
                        onConfirm: {
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

