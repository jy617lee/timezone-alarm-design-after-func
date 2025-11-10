//
//  TrashIconView.swift
//  TimezoneAlarm
//
//  Created on 2024.
//

import SwiftUI

struct TrashIconView: View {
    var size: CGFloat = 14
    var color: Color = .appTextSecondary
    
    // SVG viewBox="0 0 24 24"를 size로 스케일링
    private var scale: CGFloat {
        size / 24.0
    }
    
    var body: some View {
        ZStack {
            // 상단 가로선: M3 6h18
            Path { path in
                path.move(to: CGPoint(x: 3 * scale, y: 6 * scale))
                path.addLine(to: CGPoint(x: 21 * scale, y: 6 * scale))
            }
            .stroke(color, lineWidth: 2 * scale)
            
            // 몸체: M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6
            Path { path in
                path.move(to: CGPoint(x: 19 * scale, y: 6 * scale))
                path.addLine(to: CGPoint(x: 19 * scale, y: 20 * scale))
                // c0 1-1 2-2 2 -> 곡선: (0, 1) 상대, (-1, 2) 상대, (-2, 2) 상대
                path.addCurve(
                    to: CGPoint(x: 17 * scale, y: 22 * scale),
                    control1: CGPoint(x: 19 * scale, y: 21 * scale),
                    control2: CGPoint(x: 18 * scale, y: 22 * scale)
                )
                path.addLine(to: CGPoint(x: 7 * scale, y: 22 * scale))
                // c-1 0-2-1-2-2 -> 곡선: (-1, 0) 상대, (-2, -1) 상대, (-2, -2) 상대
                path.addCurve(
                    to: CGPoint(x: 5 * scale, y: 20 * scale),
                    control1: CGPoint(x: 6 * scale, y: 22 * scale),
                    control2: CGPoint(x: 5 * scale, y: 21 * scale)
                )
                path.addLine(to: CGPoint(x: 5 * scale, y: 6 * scale))
            }
            .stroke(color, lineWidth: 2 * scale)
            
            // 손잡이: M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2
            Path { path in
                path.move(to: CGPoint(x: 8 * scale, y: 6 * scale))
                path.addLine(to: CGPoint(x: 8 * scale, y: 4 * scale))
                // c0-1 1-2 2-2 -> 곡선: (0, -1) 상대, (1, -2) 상대, (2, -2) 상대
                path.addCurve(
                    to: CGPoint(x: 10 * scale, y: 2 * scale),
                    control1: CGPoint(x: 8 * scale, y: 3 * scale),
                    control2: CGPoint(x: 9 * scale, y: 2 * scale)
                )
                path.addLine(to: CGPoint(x: 14 * scale, y: 2 * scale))
                // c1 0 2 1 2 2 -> 곡선: (1, 0) 상대, (2, 1) 상대, (2, 2) 상대
                path.addCurve(
                    to: CGPoint(x: 16 * scale, y: 4 * scale),
                    control1: CGPoint(x: 15 * scale, y: 2 * scale),
                    control2: CGPoint(x: 16 * scale, y: 3 * scale)
                )
                path.addLine(to: CGPoint(x: 16 * scale, y: 6 * scale))
            }
            .stroke(color, lineWidth: 2 * scale)
            
            // 왼쪽 세로줄: line x1="10" x2="10" y1="11" y2="17"
            Path { path in
                path.move(to: CGPoint(x: 10 * scale, y: 11 * scale))
                path.addLine(to: CGPoint(x: 10 * scale, y: 17 * scale))
            }
            .stroke(color, lineWidth: 2 * scale)
            
            // 오른쪽 세로줄: line x1="14" x2="14" y1="11" y2="17"
            Path { path in
                path.move(to: CGPoint(x: 14 * scale, y: 11 * scale))
                path.addLine(to: CGPoint(x: 14 * scale, y: 17 * scale))
            }
            .stroke(color, lineWidth: 2 * scale)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    TrashIconView()
        .padding()
}

