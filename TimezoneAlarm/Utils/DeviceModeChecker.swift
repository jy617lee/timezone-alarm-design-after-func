//
//  DeviceModeChecker.swift
//  TimezoneAlarm
//
//  기기 모드 상태 enum
//

import Foundation

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

