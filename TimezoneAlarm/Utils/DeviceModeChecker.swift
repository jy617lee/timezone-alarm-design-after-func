//
//  DeviceModeChecker.swift
//  TimezoneAlarm
//
//  무음모드 및 방해금지모드 감지 유틸리티
//

import Foundation
import UserNotifications
import AVFoundation

/// 기기 모드 상태
enum DeviceModeState: Equatable {
    case normal
    case silentMode
    case doNotDisturb
    case both
    
    var rawValue: String {
        switch self {
        case .normal:
            return "normal"
        case .silentMode:
            return "silentMode"
        case .doNotDisturb:
            return "doNotDisturb"
        case .both:
            return "both"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "normal":
            self = .normal
        case "silentMode":
            self = .silentMode
        case "doNotDisturb":
            self = .doNotDisturb
        case "both":
            self = .both
        default:
            return nil
        }
    }
}

/// 무음모드 및 방해금지모드 감지 유틸리티
final class DeviceModeChecker: Sendable {
    static let shared = DeviceModeChecker()
    
    private init() {}
    
    /// 현재 기기의 무음 모드 및 방해금지 모드 상태를 확인합니다.
    /// - Returns: DeviceModeState (normal, silentMode, doNotDisturb, both)
    func checkDeviceMode() async -> DeviceModeState {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        var isSilentMode = false
        var isDoNotDisturb = false
        
        // 무음모드 감지
        // iOS에서는 하드웨어 무음 스위치를 직접 감지할 수 없습니다.
        // soundSetting이 disabled인 경우를 무음모드로 간주합니다.
        if settings.soundSetting == .disabled {
            isSilentMode = true
        }
        
        // 방해금지모드 감지
        // alertSetting이 disabled이거나, soundSetting이 disabled인 경우를 방해금지모드로 간주합니다.
        // iOS 15+에서는 scheduledDeliverySetting을 사용할 수 있지만, 하위 호환성을 위해 soundSetting을 사용합니다.
        if settings.alertSetting == .disabled || settings.soundSetting == .disabled {
            isDoNotDisturb = true
        }
        
        // 두 모드가 모두 활성화된 경우
        if isSilentMode && isDoNotDisturb {
            return .both
        } else if isSilentMode {
            return .silentMode
        } else if isDoNotDisturb {
            return .doNotDisturb
        } else {
            return .normal
        }
    }
    
    /// 앱이 방해금지모드 예외 앱으로 등록되어 있는지 확인합니다.
    /// - Returns: true면 예외 앱으로 등록됨, false면 등록되지 않음
    func isDoNotDisturbException() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        // soundSetting이 enabled이면 예외 앱으로 등록된 것으로 간주
        // 방해금지모드에서도 소리가 나면 예외 앱으로 등록된 것
        return settings.soundSetting == .enabled
    }
    
    /// 방해금지모드 설정 페이지 URL을 반환합니다.
    /// - Returns: 방해금지모드 설정 URL
    func getDoNotDisturbSettingsURL() -> URL? {
        // iOS에서 방해금지모드 설정 페이지로 이동하는 URL
        // App-Prefs:root=DO_NOT_DISTURB
        return URL(string: "App-Prefs:root=DO_NOT_DISTURB")
    }
}

