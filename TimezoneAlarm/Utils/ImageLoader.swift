//
//  ImageLoader.swift
//  TimezoneAlarm
//
//  Resources 폴더의 이미지를 로드하기 위한 유틸리티
//

import SwiftUI

extension Image {
    /// Resources 폴더에서 이미지를 로드
    static func fromResources(_ name: String) -> Image {
        if let uiImage = UIImage(named: name, in: Bundle.main, compatibleWith: nil) {
            return Image(uiImage: uiImage)
        }
        // 폴백: 시스템 이미지 또는 빈 이미지
        return Image(systemName: "photo")
    }
}








