//
//  AppRootView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct AppRootView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isPresented: $showSplash)
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showSplash)
    }
}

#Preview {
    AppRootView()
        .environmentObject(NotificationDelegate.shared)
}

