# Agent.md - iOS Timezone Alarm App

## Project Overview

This project is an iOS app for managing alarms across multiple timezones. Users can set a specific timezone for each alarm and configure alarms using that timezone's time.

## Core Requirements

### Timezone Handling
- **Important**: Each alarm displays the time in its configured timezone (NOT converted to local time)
- Example: If set to 6:00 AM in Seoul timezone, it always displays as "6:00 AM 🇰🇷Seoul"
- When the alarm triggers, it also displays the current time in that timezone (e.g., "Current Seoul time: 6:00 AM")
- Local notification scheduling must consider timezones to trigger at the exact time

## Technology Stack

- **Platform**: iOS 17+
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable (iOS 17+)
- **Storage**: SwiftData (recommended for iOS 17+) or UserDefaults
- **Notifications**: UserNotifications framework
- **Timezone**: Foundation TimeZone

- Use Swift 6.0 syntax
- State management using `@Observable` macro (iOS 17+)
- Follow MVVM pattern
- Business logic separated into Service layer
- **NEVER convert to local time for display** - display each alarm's timezone time as-is
- Prefer SwiftUI native components

## Architecture

- **MVVM with @Observable**: Use `@Observable` macro (not `ObservableObject`)
- **Structure**: Models / ViewModels / Views / Services / Utilities
- **ViewModels**: Handle UI state, delegate complex operations to Services
- **Services**: Business logic layer, injectable and testable
- **Dependency Injection**: Use protocols for dependencies

## Implementation Guidelines

### Timezone Handling
- **Display**: Always show alarm time in its configured timezone (NEVER convert to local time)
- **Storage**: Store as components (hour, minute) + timezone identifier, not absolute `Date`
- **Notifications**: Calculate trigger date in the alarm's timezone using `DateComponents`
- **Formatting**: Use `DateFormatter` with alarm's timezone for display

### Notifications
- Use `UNUserNotificationCenter`, schedule based on alarm's timezone
- Handle DST and timezone changes (may need rescheduling)

### Swift 6.0
- Use `async/await`, `@MainActor` for UI updates
- Prefer `Task` over `DispatchQueue`

### Testing
- Unit tests for timezone logic, notifications, ViewModels, Services
- Mock dependencies via protocols

## Code Quality

- **SOLID Principles**: Follow SRP, use protocols for dependencies, inject via initializers
- **DRY**: Extract common logic (formatting, UI patterns) into extensions/reusable components
- **Organization**: Small focused functions, meaningful names, use `// MARK:` for grouping

## Development Workflow

**Test-Driven Development (TDD)**
1. Write unit tests first for each feature
2. Implement the feature to make tests pass
3. Only commit when all tests pass
4. Commit in meaningful units (models, services, viewmodels, views, etc.)
