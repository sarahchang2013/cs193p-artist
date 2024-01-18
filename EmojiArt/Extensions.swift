//
//  Extensions.swift
//  EmojiArt
//
//  Created by sarahchangzsy on 2024/1/18.
//

import SwiftUI

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
