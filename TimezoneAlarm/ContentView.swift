//
//  ContentView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 알람 아이콘
            Image(systemName: "alarm")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            // Title
            Text("No Alarms Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Description
            Text("Tap + to add your first alarm")
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Add New Alarm 버튼
            Button(action: {
                // TODO: Add alarm action
            }) {
                Text("Add New Alarm")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

