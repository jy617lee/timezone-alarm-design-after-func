//
//  DeviceModeCheckerTests.swift
//  TimezoneAlarmTests
//
//  DeviceModeChecker 유틸리티 테스트
//

import XCTest
@testable import TimezoneAlarm
import UserNotifications

final class DeviceModeCheckerTests: XCTestCase {
    
    var deviceModeChecker: DeviceModeChecker!
    
    override func setUp() {
        super.setUp()
        deviceModeChecker = DeviceModeChecker.shared
    }
    
    override func tearDown() {
        deviceModeChecker = nil
        super.tearDown()
    }
    
    /// DeviceModeChecker가 싱글톤인지 확인
    func testDeviceModeCheckerIsSingleton() {
        let instance1 = DeviceModeChecker.shared
        let instance2 = DeviceModeChecker.shared
        
        XCTAssertTrue(instance1 === instance2, "DeviceModeChecker는 싱글톤이어야 합니다")
    }
    
    /// checkDeviceMode가 정상적으로 동작하는지 확인
    /// 실제 기기 설정에 따라 결과가 달라질 수 있으므로, 에러가 발생하지 않는지만 확인
    /// 방해금지모드인데 예외 앱으로 등록되어 있으면 .normal을 반환해야 함
    func testCheckDeviceMode() async {
        let mode = await deviceModeChecker.checkDeviceMode()
        
        // DeviceModeState는 enum이므로 항상 유효한 값이어야 함
        // 방해금지모드인데 예외 앱이면 .normal을 반환하므로, .doNotDisturb나 .both는 예외가 아닌 경우에만 반환됨
        switch mode {
        case .normal, .silentMode, .doNotDisturb, .both:
            // 정상적인 경우
            break
        }
    }
    
    /// getDoNotDisturbSettingsURL이 올바른 URL을 반환하는지 확인
    func testGetDoNotDisturbSettingsURL() {
        let url = deviceModeChecker.getDoNotDisturbSettingsURL()
        
        // URL이 nil이 아니어야 함
        XCTAssertNotNil(url, "방해금지모드 설정 URL이 반환되어야 합니다")
        
        // URL 스킴이 올바른지 확인
        if let url = url {
            XCTAssertEqual(url.scheme, "App-Prefs", "URL 스킴이 App-Prefs여야 합니다")
            // App-Prefs: 스킴의 URL은 path가 "root=DO_NOT_DISTURB" 형태일 수 있음
            // 또는 host가 nil일 수 있으므로, 스킴만 확인
        }
    }
}

