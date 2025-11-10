//
//  Logger.swift
//  TimezoneAlarm
//
//  로그 유틸리티 - 개발 환경에서만 동작
//

import Foundation

/// 개발 환경에서만 로그를 출력하는 함수
/// - Parameter message: 출력할 메시지
func debugLog(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

/// 개발 환경에서만 로그를 출력하는 함수 (파일명, 함수명, 라인 번호 포함)
/// - Parameters:
///   - message: 출력할 메시지
///   - file: 파일명 (기본값: #file)
///   - function: 함수명 (기본값: #function)
///   - line: 라인 번호 (기본값: #line)
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) - \(message)")
    #endif
}

