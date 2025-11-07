//
//  Country.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import Foundation

struct Country: Identifiable, Hashable {
    let id: String
    let name: String
    let flag: String
    let timezoneIdentifier: String
    
    static let popularCountries: [Country] = [
        Country(id: "KR", name: "South Korea", flag: "🇰🇷", timezoneIdentifier: "Asia/Seoul"),
        Country(id: "US", name: "United States", flag: "🇺🇸", timezoneIdentifier: "America/New_York"),
        Country(id: "JP", name: "Japan", flag: "🇯🇵", timezoneIdentifier: "Asia/Tokyo"),
        Country(id: "CN", name: "China", flag: "🇨🇳", timezoneIdentifier: "Asia/Shanghai"),
        Country(id: "GB", name: "United Kingdom", flag: "🇬🇧", timezoneIdentifier: "Europe/London"),
        Country(id: "DE", name: "Germany", flag: "🇩🇪", timezoneIdentifier: "Europe/Berlin"),
        Country(id: "FR", name: "France", flag: "🇫🇷", timezoneIdentifier: "Europe/Paris"),
        Country(id: "AU", name: "Australia", flag: "🇦🇺", timezoneIdentifier: "Australia/Sydney"),
        Country(id: "CA", name: "Canada", flag: "🇨🇦", timezoneIdentifier: "America/Toronto"),
        Country(id: "BR", name: "Brazil", flag: "🇧🇷", timezoneIdentifier: "America/Sao_Paulo"),
        Country(id: "IN", name: "India", flag: "🇮🇳", timezoneIdentifier: "Asia/Kolkata"),
        Country(id: "RU", name: "Russia", flag: "🇷🇺", timezoneIdentifier: "Europe/Moscow"),
        Country(id: "MX", name: "Mexico", flag: "🇲🇽", timezoneIdentifier: "America/Mexico_City"),
        Country(id: "IT", name: "Italy", flag: "🇮🇹", timezoneIdentifier: "Europe/Rome"),
        Country(id: "ES", name: "Spain", flag: "🇪🇸", timezoneIdentifier: "Europe/Madrid"),
    ]
}

