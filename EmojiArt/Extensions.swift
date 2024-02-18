//
//  Extensions.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI

typealias CGOffset = CGSize

extension String {
    // (inefficiently) remove duplicate characters and preserve order
    var uniqued: String {
        reduce(into: "") {sofar, element in
            if !sofar.contains(element) {
                sofar.append(element)
            }
        }
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
    init(center: CGPoint, size: CGSize) {
        self.init(origin: CGPoint(x:center.x-size.width/2, y:center.y-size.height/2),size: size)
    }
}

extension CGOffset {
    static func +(lop: CGOffset, rop: CGOffset) -> CGOffset {
        CGOffset(width: lop.width + rop.width, height: lop.height + rop.height)
    }
    
    static func +=(lop: inout CGOffset, rop: CGOffset) {
        lop = lop + rop
    }
}

struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    var role: ButtonRole?
    let action: () -> Void
    
    init(_ title: String? = nil,
         systemImage: String? = nil,
         role: ButtonRole? = nil,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button(role: role) {
            withAnimation {
                action()
            }
        } label: {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
            } else if let title {
                Text(title)
            } else if let systemImage {
                Image(systemName: systemImage)
            }
        }
    }
}
