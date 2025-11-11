//
//  SplashView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0.0
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // 알람 실행 화면과 동일한 그라데이션 백그라운드
            LinearGradient(
                colors: [Color.appBackgroundTop, Color.appBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.2)
                    
                    // 알람 아이콘
                    Image("alarm-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 270, height: 270)
                        .opacity(opacity)
                    
                    // Syncly 제목
                    Text("Syncly")
                        .font(.geist(size: 48, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .padding(.top, 12)
                        .opacity(opacity)
                    
                    // 서브타이틀
                    Text("Stay in sync with every city")
                        .font(.geist(size: 20, weight: .light))
                        .foregroundColor(.appTextSecondary)
                        .padding(.top, 6)
                        .opacity(opacity)
                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.8)
                }
                .frame(width: geometry.size.width)
            }
        }
        .onAppear {
            // 조용한 fade in 애니메이션
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
            
            // 2초 후 바로 화면 전환 (fade out 없음)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isPresented = false
            }
        }
    }
}

#Preview {
    SplashView(isPresented: .constant(true))
}

