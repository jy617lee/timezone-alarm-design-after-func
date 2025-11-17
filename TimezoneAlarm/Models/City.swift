//
//  City.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation

struct City: Identifiable, Hashable {
    let id: String // timezoneIdentifier를 id로 사용
    let name: String // 도시명만 표시 (예: "Seoul", "New York")
    let countryName: String // 국가명 (표시용)
    let countryFlag: String // 국기 이모지 (표시용)
    let timezoneIdentifier: String // 실제 타임존 식별자
    
    static let popularCities: [City] = [
        // Asia
        City(id: "Asia/Seoul", name: "Seoul", countryName: "South Korea", countryFlag: "🇰🇷", timezoneIdentifier: "Asia/Seoul"),
        City(id: "Asia/Tokyo", name: "Tokyo", countryName: "Japan", countryFlag: "🇯🇵", timezoneIdentifier: "Asia/Tokyo"),
        City(id: "Asia/Shanghai", name: "Shanghai", countryName: "China", countryFlag: "🇨🇳", timezoneIdentifier: "Asia/Shanghai"),
        City(id: "Asia/Hong_Kong", name: "Hong Kong", countryName: "Hong Kong", countryFlag: "🇭🇰", timezoneIdentifier: "Asia/Hong_Kong"),
        City(id: "Asia/Singapore", name: "Singapore", countryName: "Singapore", countryFlag: "🇸🇬", timezoneIdentifier: "Asia/Singapore"),
        City(id: "Asia/Bangkok", name: "Bangkok", countryName: "Thailand", countryFlag: "🇹🇭", timezoneIdentifier: "Asia/Bangkok"),
        City(id: "Asia/Dubai", name: "Dubai", countryName: "UAE", countryFlag: "🇦🇪", timezoneIdentifier: "Asia/Dubai"),
        City(id: "Asia/Kolkata", name: "Mumbai", countryName: "India", countryFlag: "🇮🇳", timezoneIdentifier: "Asia/Kolkata"),
        City(id: "Asia/Jakarta", name: "Jakarta", countryName: "Indonesia", countryFlag: "🇮🇩", timezoneIdentifier: "Asia/Jakarta"),
        City(id: "Asia/Manila", name: "Manila", countryName: "Philippines", countryFlag: "🇵🇭", timezoneIdentifier: "Asia/Manila"),
        
        // North America
        City(id: "America/New_York", name: "New York", countryName: "United States", countryFlag: "🇺🇸", timezoneIdentifier: "America/New_York"),
        City(id: "America/Los_Angeles", name: "LA", countryName: "United States", countryFlag: "🇺🇸", timezoneIdentifier: "America/Los_Angeles"),
        City(id: "America/Chicago", name: "Chicago", countryName: "United States", countryFlag: "🇺🇸", timezoneIdentifier: "America/Chicago"),
        City(id: "America/Denver", name: "Denver", countryName: "United States", countryFlag: "🇺🇸", timezoneIdentifier: "America/Denver"),
        City(id: "America/Toronto", name: "Toronto", countryName: "Canada", countryFlag: "🇨🇦", timezoneIdentifier: "America/Toronto"),
        City(id: "America/Vancouver", name: "Vancouver", countryName: "Canada", countryFlag: "🇨🇦", timezoneIdentifier: "America/Vancouver"),
        City(id: "America/Mexico_City", name: "Mexico City", countryName: "Mexico", countryFlag: "🇲🇽", timezoneIdentifier: "America/Mexico_City"),
        
        // Europe
        City(id: "Europe/London", name: "London", countryName: "United Kingdom", countryFlag: "🇬🇧", timezoneIdentifier: "Europe/London"),
        City(id: "Europe/Paris", name: "Paris", countryName: "France", countryFlag: "🇫🇷", timezoneIdentifier: "Europe/Paris"),
        City(id: "Europe/Berlin", name: "Berlin", countryName: "Germany", countryFlag: "🇩🇪", timezoneIdentifier: "Europe/Berlin"),
        City(id: "Europe/Rome", name: "Rome", countryName: "Italy", countryFlag: "🇮🇹", timezoneIdentifier: "Europe/Rome"),
        City(id: "Europe/Madrid", name: "Madrid", countryName: "Spain", countryFlag: "🇪🇸", timezoneIdentifier: "Europe/Madrid"),
        City(id: "Europe/Amsterdam", name: "Amsterdam", countryName: "Netherlands", countryFlag: "🇳🇱", timezoneIdentifier: "Europe/Amsterdam"),
        City(id: "Europe/Moscow", name: "Moscow", countryName: "Russia", countryFlag: "🇷🇺", timezoneIdentifier: "Europe/Moscow"),
        City(id: "Europe/Istanbul", name: "Istanbul", countryName: "Turkey", countryFlag: "🇹🇷", timezoneIdentifier: "Europe/Istanbul"),
        
        // Oceania
        City(id: "Australia/Sydney", name: "Sydney", countryName: "Australia", countryFlag: "🇦🇺", timezoneIdentifier: "Australia/Sydney"),
        City(id: "Australia/Melbourne", name: "Melbourne", countryName: "Australia", countryFlag: "🇦🇺", timezoneIdentifier: "Australia/Melbourne"),
        City(id: "Pacific/Auckland", name: "Auckland", countryName: "New Zealand", countryFlag: "🇳🇿", timezoneIdentifier: "Pacific/Auckland"),
        
        // South America
        City(id: "America/Sao_Paulo", name: "São Paulo", countryName: "Brazil", countryFlag: "🇧🇷", timezoneIdentifier: "America/Sao_Paulo"),
        City(id: "America/Buenos_Aires", name: "Buenos Aires", countryName: "Argentina", countryFlag: "🇦🇷", timezoneIdentifier: "America/Buenos_Aires"),
    ]
}

